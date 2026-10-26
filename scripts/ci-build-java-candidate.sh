#!/usr/bin/env sh
set -eu

: "${DRONE_BUILD_NUMBER:?Drone build number is required}"
: "${DRONE_BUILD_EVENT:?Drone build event is required}"
: "${DRONE_BRANCH:?Drone branch is required}"
: "${DRONE_COMMIT_SHA:?Drone commit SHA is required}"

if [ "$DRONE_BUILD_EVENT" != push ] || [ "$DRONE_BRANCH" != 25 ]; then
  printf '%s\n' 'Java candidates are allowed only on pushes to the 25 maintenance branch.' >&2
  exit 1
fi

base_ref=$(awk '$1 == "FROM" && $2 ~ /^kernel528\/alpine:/ { print $2; exit }' jdk/Dockerfile)
base_tag=${base_ref##*:}
expected_alpine=${base_tag%_*}
java_env=$(awk '$1 == "ENV" && $2 ~ /^JAVA_VERSION=/ { sub(/^JAVA_VERSION=/, "", $2); print $2; exit }' jdk/Dockerfile)
java_tag=${java_env#jdk-}
java_tag=$(printf '%s\n' "$java_tag" | tr '+' '-')
java_version=${java_env#jdk-}
java_version=${java_version%%+*}
jdk_image="localhost/java-jdk-candidate:${DRONE_BUILD_NUMBER}-${DRONE_COMMIT_SHA}"
jre_image="localhost/java-jre-candidate:${DRONE_BUILD_NUMBER}-${DRONE_COMMIT_SHA}"
jdk_candidate_tag="jdk${java_tag}_${base_tag}-drone-build-${DRONE_BUILD_NUMBER}"
jre_candidate_tag="jre${java_tag}_${base_tag}-drone-build-${DRONE_BUILD_NUMBER}"

if [ -z "$base_tag" ] || [ -z "$expected_alpine" ] || [ -z "$java_tag" ] || [ -z "$java_version" ]; then
  printf '%s\n' 'Could not determine the pinned Alpine base or Java version.' >&2
  exit 1
fi

attempt=0
until docker info >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    printf '%s\n' 'Docker-in-Docker service did not become ready.' >&2
    exit 1
  fi
  sleep 1
done

docker build --pull --no-cache --tag "$jdk_image" --file jdk/Dockerfile .
docker build --pull --no-cache --tag "$jre_image" --file jre/Dockerfile .
jdk_image_id=$(docker image inspect --format '{{.Id}}' "$jdk_image")
jre_image_id=$(docker image inspect --format '{{.Id}}' "$jre_image")
printf 'Java candidate JDK image ID: %s\n' "$jdk_image_id"
printf 'Java candidate JRE image ID: %s\n' "$jre_image_id"
printf 'Java candidate tags after publish: %s and %s\n' "$jdk_candidate_tag" "$jre_candidate_tag"
scripts/ci-smoke-java-images.sh "$jdk_image_id" "$jre_image_id" "$expected_alpine" "$java_version"

umask 077
printf '%s\n' "$jdk_image_id" > .drone-java-jdk-image-id
printf '%s\n' "$jre_image_id" > .drone-java-jre-image-id
printf '%s\n' "$jdk_candidate_tag" > .drone-java-jdk-image-tag
printf '%s\n' "$jre_candidate_tag" > .drone-java-jre-image-tag
printf '%s\n' "$DRONE_COMMIT_SHA" > .drone-java-commit
