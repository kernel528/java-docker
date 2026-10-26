#!/usr/bin/env sh
set -eu

: "${DRONE_BUILD_EVENT:?Drone build event is required}"
: "${DRONE_TAG:?Release tag is required}"
: "${DRONE_COMMIT_REF:?Git ref is required}"
: "${DRONE_COMMIT_SHA:?Commit SHA is required}"
: "${JAVA_IMAGE_REPO:?Java image repository is required}"
: "${DOCKER_USERNAME:?Docker username secret is required}"
: "${DOCKER_PASSWORD:?Docker password secret is required}"

if [ "$DRONE_BUILD_EVENT" != tag ] || [ "$DRONE_COMMIT_REF" != "refs/tags/$DRONE_TAG" ]; then
  printf '%s\n' 'Java release publication requires its matching Git tag event.' >&2
  exit 1
fi

jdk_image_id=$(cat .drone-java-jdk-image-id)
jre_image_id=$(cat .drone-java-jre-image-id)
release_tag=$(cat .drone-java-release-tag)
release_commit=$(cat .drone-java-commit)

if [ "$release_tag" != "$DRONE_TAG" ] || [ "$release_commit" != "$DRONE_COMMIT_SHA" ]; then
  printf '%s\n' 'Java release metadata does not match the Drone tag or source commit.' >&2
  exit 1
fi

case "$jdk_image_id:$jre_image_id" in
  sha256:*:sha256:*) ;;
  *) printf '%s\n' 'Java release artifacts do not contain immutable image IDs.' >&2; exit 1 ;;
esac

docker image inspect "$jdk_image_id" >/dev/null
docker image inspect "$jre_image_id" >/dev/null
jdk_ref="${JAVA_IMAGE_REPO}:jdk${release_tag}"
jre_ref="${JAVA_IMAGE_REPO}:jre${release_tag}"
docker_config=$(mktemp -d)
cleanup() {
  rc=$?
  trap - EXIT
  rm -rf "$docker_config" || rc=1
  rm -f .drone-java-jdk-image-id .drone-java-jre-image-id .drone-java-release-tag .drone-java-commit || rc=1
  exit "$rc"
}
trap cleanup EXIT
export DOCKER_CONFIG=$docker_config
printf '%s' "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin

for image_ref in "$jdk_ref" "$jre_ref"; do
  if manifest_output=$(docker manifest inspect "$image_ref" 2>&1); then
    printf 'Refusing to overwrite immutable Java release %s.\n' "$image_ref" >&2
    exit 1
  else
    case "$manifest_output" in
      *MANIFEST_UNKNOWN*|*"manifest unknown"*|*"no such manifest"*) ;;
      *) printf 'Could not verify Java release tag is unused: %s\n' "$manifest_output" >&2; exit 1 ;;
    esac
  fi
done

docker image tag "$jdk_image_id" "$jdk_ref"
docker image tag "$jre_image_id" "$jre_ref"
if [ "$(docker image inspect --format '{{.Id}}' "$jdk_ref")" != "$jdk_image_id" ] || \
   [ "$(docker image inspect --format '{{.Id}}' "$jre_ref")" != "$jre_image_id" ]; then
  printf '%s\n' 'Java release tags are not attached to the tested image IDs.' >&2
  exit 1
fi

if jdk_push_output=$(docker image push "$jdk_ref" 2>&1); then
  printf '%s\n' "$jdk_push_output"
else
  printf '%s\n' "$jdk_push_output" >&2
  exit 1
fi
jdk_digest=$(printf '%s\n' "$jdk_push_output" | awk '$2 == "digest:" { print $3; exit }')
case "$jdk_digest" in
  sha256:*) printf 'Immutable Java JDK release digest: %s\n' "$jdk_digest" ;;
  *) printf '%s\n' 'JDK registry push succeeded without reporting a manifest digest.' >&2; exit 1 ;;
esac

if jre_push_output=$(docker image push "$jre_ref" 2>&1); then
  printf '%s\n' "$jre_push_output"
else
  printf '%s\n' "$jre_push_output" >&2
  exit 1
fi
jre_digest=$(printf '%s\n' "$jre_push_output" | awk '$2 == "digest:" { print $3; exit }')
case "$jre_digest" in
  sha256:*) printf 'Immutable Java JRE release digest: %s\n' "$jre_digest" ;;
  *) printf '%s\n' 'JRE registry push succeeded without reporting a manifest digest.' >&2; exit 1 ;;
esac

for alias in jdk-latest jre-latest; do
  alias_ref="${JAVA_IMAGE_REPO}:${alias}"
  case "$alias" in
    jdk-latest) image_id=$jdk_image_id; expected_digest=$jdk_digest ;;
    jre-latest) image_id=$jre_image_id; expected_digest=$jre_digest ;;
  esac
  docker image tag "$image_id" "$alias_ref"
  if [ "$(docker image inspect --format '{{.Id}}' "$alias_ref")" != "$image_id" ]; then
    printf 'Java alias %s is not attached to its tested image ID.\n' "$alias" >&2
    exit 1
  fi
  if alias_push_output=$(docker image push "$alias_ref" 2>&1); then
    printf '%s\n' "$alias_push_output"
  else
    printf '%s\n' "$alias_push_output" >&2
    exit 1
  fi
  alias_digest=$(printf '%s\n' "$alias_push_output" | awk '$2 == "digest:" { print $3; exit }')
  if [ "$alias_digest" != "$expected_digest" ]; then
    printf 'Java alias %s digest %s differs from release digest %s.\n' \
      "$alias" "${alias_digest:-missing}" "$expected_digest" >&2
    exit 1
  fi
done

printf 'Published %s and %s; jdk-latest and jre-latest match their tested immutable releases.\n' \
  "$jdk_ref" "$jre_ref"
