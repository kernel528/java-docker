#!/usr/bin/env sh
set -eu

jdk_image_id=${1:?Usage: ci-smoke-java-images.sh <jdk-image-id> <jre-image-id> <alpine-release> <java-version>}
jre_image_id=${2:?Usage: ci-smoke-java-images.sh <jdk-image-id> <jre-image-id> <alpine-release> <java-version>}
expected_alpine=${3:?Usage: ci-smoke-java-images.sh <jdk-image-id> <jre-image-id> <alpine-release> <java-version>}
expected_java=${4:?Usage: ci-smoke-java-images.sh <jdk-image-id> <jre-image-id> <alpine-release> <java-version>}
smoke_volume="java-smoke-$$"

cleanup() {
  rc=$?
  trap - EXIT
  if [ -n "$smoke_volume" ]; then
    docker volume rm --force "$smoke_volume" >/dev/null 2>&1 || rc=1
  fi
  exit "$rc"
}
trap cleanup EXIT

for image_id in "$jdk_image_id" "$jre_image_id"; do
  actual_alpine=$(docker container run --rm "$image_id" cat /etc/alpine-release)
  if [ "$actual_alpine" != "$expected_alpine" ]; then
    printf 'Alpine release mismatch in %s: expected %s, got %s\n' \
      "$image_id" "$expected_alpine" "$actual_alpine" >&2
    exit 1
  fi
  java_output=$(docker container run --rm "$image_id" java --version 2>&1)
  case "$java_output" in
    *"$expected_java"*) ;;
    *) printf 'Java version mismatch in %s; expected %s, got:\n%s\n' "$image_id" "$expected_java" "$java_output" >&2; exit 1 ;;
  esac
done

javac_output=$(docker container run --rm "$jdk_image_id" javac --version 2>&1)
case "$javac_output" in
  *"$expected_java"*) ;;
  *) printf 'JDK compiler version mismatch; expected %s, got %s\n' "$expected_java" "$javac_output" >&2; exit 1 ;;
esac

docker volume create "$smoke_volume" >/dev/null
docker container run --rm -i --volume "$smoke_volume:/tmp/java-smoke" "$jdk_image_id" \
  sh -c 'cat > /tmp/java-smoke/HelloWorld.java && javac -d /tmp/java-smoke /tmp/java-smoke/HelloWorld.java' \
  < src/hello-world/HelloWorld.java
output=$(docker container run --rm --volume "$smoke_volume:/tmp/java-smoke" "$jre_image_id" \
  java -classpath /tmp/java-smoke HelloWorld)
if [ "$output" != 'Hello, World' ]; then
  printf 'JRE HelloWorld output mismatch: %s\n' "$output" >&2
  exit 1
fi

printf 'Java smoke checks passed: Alpine %s, JDK/JRE %s, HelloWorld compiled and ran.\n' \
  "$expected_alpine" "$expected_java"
