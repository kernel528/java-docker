#!/usr/bin/env sh
set -eu

: "${DRONE_BUILD_NUMBER:?Drone build number is required}"
: "${DRONE_BUILD_EVENT:?Drone build event is required}"
: "${DRONE_TAG:?Release tag is required}"
: "${DRONE_COMMIT_REF:?Git ref is required}"
: "${DRONE_COMMIT_SHA:?Commit SHA is required}"

if [ "$DRONE_BUILD_EVENT" != tag ] || [ "$DRONE_COMMIT_REF" != "refs/tags/$DRONE_TAG" ]; then
  printf '%s\n' 'Java release builds require their matching Git tag event.' >&2
  exit 1
fi

base_ref=$(awk '$1 == "FROM" && $2 ~ /^kernel528\/alpine:/ { print $2; exit }' jdk/Dockerfile)
base_tag=${base_ref##*:}
expected_alpine=${base_tag%_*}
java_env=$(awk '$1 == "ENV" && $2 ~ /^JAVA_VERSION=/ { sub(/^JAVA_VERSION=/, "", $2); print $2; exit }' jdk/Dockerfile)
java_tag=$(printf '%s\n' "${java_env#jdk-}" | tr '+' '-')
java_version=${java_env#jdk-}
java_version=${java_version%%+*}
expected_tag="${java_tag}_${base_tag}"
jdk_image="localhost/java-jdk-release:${DRONE_BUILD_NUMBER}-${DRONE_COMMIT_SHA}"
jre_image="localhost/java-jre-release:${DRONE_BUILD_NUMBER}-${DRONE_COMMIT_SHA}"

if [ "$DRONE_TAG" != "$expected_tag" ]; then
  printf 'Java release tag mismatch: expected %s, got %s.\n' "$expected_tag" "$DRONE_TAG" >&2
  exit 1
fi

if ! awk -v tag="- v${DRONE_TAG}:" 'index($0, tag) == 1 { found = 1 } END { exit !found }' VERSION.md; then
  printf 'Java release tag %s is not recorded in VERSION.md.\n' "$DRONE_TAG" >&2
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
printf 'Java release source commit: %s\n' "$DRONE_COMMIT_SHA"
printf 'Java release tag: %s\n' "$DRONE_TAG"
printf 'Java JDK image ID: %s\n' "$jdk_image_id"
printf 'Java JRE image ID: %s\n' "$jre_image_id"
scripts/ci-smoke-java-images.sh "$jdk_image_id" "$jre_image_id" "$expected_alpine" "$java_version"

umask 077
printf '%s\n' "$jdk_image_id" > .drone-java-jdk-image-id
printf '%s\n' "$jre_image_id" > .drone-java-jre-image-id
printf '%s\n' "$DRONE_TAG" > .drone-java-release-tag
printf '%s\n' "$DRONE_COMMIT_SHA" > .drone-java-commit
