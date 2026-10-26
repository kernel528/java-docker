#!/usr/bin/env sh
set -eu

: "${DRONE_BUILD_NUMBER:?Drone build number is required}"
: "${DRONE_BUILD_EVENT:?Drone build event is required}"
: "${DRONE_BRANCH:?Drone branch is required}"
: "${DRONE_COMMIT_SHA:?Commit SHA is required}"
: "${JAVA_IMAGE_REPO:?Java image repository is required}"
: "${DOCKER_USERNAME:?Docker username secret is required}"
: "${DOCKER_PASSWORD:?Docker password secret is required}"

if [ "$DRONE_BUILD_EVENT" != push ] || [ "$DRONE_BRANCH" != 25 ]; then
  printf '%s\n' 'Java candidates may only be published for pushes to 25.' >&2
  exit 1
fi

jdk_image_id=$(cat .drone-java-jdk-image-id)
jre_image_id=$(cat .drone-java-jre-image-id)
jdk_candidate_tag=$(cat .drone-java-jdk-image-tag)
jre_candidate_tag=$(cat .drone-java-jre-image-tag)
candidate_commit=$(cat .drone-java-commit)
base_ref=$(awk '$1 == "FROM" && $2 ~ /^kernel528\/alpine:/ { print $2; exit }' jdk/Dockerfile)
base_tag=${base_ref##*:}
java_env=$(awk '$1 == "ENV" && $2 ~ /^JAVA_VERSION=/ { sub(/^JAVA_VERSION=/, "", $2); print $2; exit }' jdk/Dockerfile)
java_tag=$(printf '%s\n' "${java_env#jdk-}" | tr '+' '-')
expected_jdk_tag="jdk${java_tag}_${base_tag}-drone-build-${DRONE_BUILD_NUMBER}"
expected_jre_tag="jre${java_tag}_${base_tag}-drone-build-${DRONE_BUILD_NUMBER}"

if [ "$candidate_commit" != "$DRONE_COMMIT_SHA" ] || \
   [ "$jdk_candidate_tag" != "$expected_jdk_tag" ] || \
   [ "$jre_candidate_tag" != "$expected_jre_tag" ]; then
  printf '%s\n' 'Java candidate metadata does not match this Drone build.' >&2
  exit 1
fi

docker image inspect "$jdk_image_id" >/dev/null
docker image inspect "$jre_image_id" >/dev/null
jdk_ref="${JAVA_IMAGE_REPO}:${jdk_candidate_tag}"
jre_ref="${JAVA_IMAGE_REPO}:${jre_candidate_tag}"
docker_config=$(mktemp -d)
cleanup() {
  rc=$?
  trap - EXIT
  rm -rf "$docker_config" || rc=1
  rm -f .drone-java-jdk-image-id .drone-java-jre-image-id .drone-java-jdk-image-tag .drone-java-jre-image-tag .drone-java-commit || rc=1
  exit "$rc"
}
trap cleanup EXIT
export DOCKER_CONFIG=$docker_config
printf '%s' "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin

for image_ref in "$jdk_ref" "$jre_ref"; do
  if manifest_output=$(docker manifest inspect "$image_ref" 2>&1); then
    printf 'Refusing to overwrite existing Java candidate %s.\n' "$image_ref" >&2
    exit 1
  else
    case "$manifest_output" in
      *MANIFEST_UNKNOWN*|*"manifest unknown"*|*"no such manifest"*) ;;
      *) printf 'Could not verify Java candidate tag is unused: %s\n' "$manifest_output" >&2; exit 1 ;;
    esac
  fi
done

for image_id in "$jdk_image_id" "$jre_image_id"; do
  if [ "$(docker image inspect --format '{{.Id}}' "$image_id")" != "$image_id" ]; then
    printf 'Java candidate image %s is unavailable.\n' "$image_id" >&2
    exit 1
  fi
done

docker image tag "$jdk_image_id" "$jdk_ref"
docker image tag "$jre_image_id" "$jre_ref"
if [ "$(docker image inspect --format '{{.Id}}' "$jdk_ref")" != "$jdk_image_id" ] || \
   [ "$(docker image inspect --format '{{.Id}}' "$jre_ref")" != "$jre_image_id" ]; then
  printf '%s\n' 'Java candidate tags do not reference the tested image IDs.' >&2
  exit 1
fi
docker image push "$jdk_ref"
docker image push "$jre_ref"
