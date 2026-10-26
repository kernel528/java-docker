#!/usr/bin/env sh
set -eu

: "${DRONE_BUILD_NUMBER:?Drone build number is required}"
: "${DRONE_COMMIT_SHA:?Drone commit SHA is required}"

base_ref=$(awk '$1 == "FROM" && $2 ~ /^kernel528\/alpine:/ { print $2; exit }' jdk/Dockerfile)
base_tag=${base_ref##*:}
expected_alpine=${base_tag%_*}
java_env=$(awk '$1 == "ENV" && $2 ~ /^JAVA_VERSION=/ { sub(/^JAVA_VERSION=/, "", $2); print $2; exit }' jdk/Dockerfile)
java_version=${java_env#jdk-}
java_version=${java_version%%+*}
jdk_image="localhost/java-jdk-ci:${DRONE_BUILD_NUMBER}-${DRONE_COMMIT_SHA}"
jre_image="localhost/java-jre-ci:${DRONE_BUILD_NUMBER}-${DRONE_COMMIT_SHA}"

if [ -z "$base_tag" ] || [ -z "$expected_alpine" ] || [ -z "$java_version" ]; then
  printf '%s\n' 'Could not determine the pinned Alpine base or Java version.' >&2
  exit 1
fi

cleanup() {
  rc=$?
  trap - EXIT
  if docker image inspect "$jdk_image" >/dev/null 2>&1; then
    docker image rm --no-prune "$jdk_image" || rc=1
  fi
  if docker image inspect "$jre_image" >/dev/null 2>&1; then
    docker image rm --no-prune "$jre_image" || rc=1
  fi
  exit "$rc"
}
trap cleanup EXIT

docker build --pull --no-cache --tag "$jdk_image" --file jdk/Dockerfile .
docker build --pull --no-cache --tag "$jre_image" --file jre/Dockerfile .
jdk_image_id=$(docker image inspect --format '{{.Id}}' "$jdk_image")
jre_image_id=$(docker image inspect --format '{{.Id}}' "$jre_image")
printf 'Rootless JDK image ID: %s\n' "$jdk_image_id"
printf 'Rootless JRE image ID: %s\n' "$jre_image_id"
scripts/ci-smoke-java-images.sh "$jdk_image_id" "$jre_image_id" "$expected_alpine" "$java_version"
