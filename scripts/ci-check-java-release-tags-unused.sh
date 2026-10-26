#!/usr/bin/env sh
set -eu

: "${DRONE_BUILD_EVENT:?Drone build event is required}"
: "${DRONE_TAG:?Release tag is required}"
: "${DRONE_COMMIT_REF:?Git ref is required}"

if [ "$DRONE_BUILD_EVENT" != tag ] || [ "$DRONE_COMMIT_REF" != "refs/tags/$DRONE_TAG" ]; then
  printf '%s\n' 'Java release preflight requires its matching Git tag event.' >&2
  exit 1
fi

for image_ref in "kernel528/java:jdk${DRONE_TAG}" "kernel528/java:jre${DRONE_TAG}"; do
  if manifest_output=$(docker manifest inspect "$image_ref" 2>&1); then
    printf 'Immutable Java release %s already exists; refusing to overwrite it.\n' "$image_ref" >&2
    exit 1
  else
    case "$manifest_output" in
      *MANIFEST_UNKNOWN*|*"manifest unknown"*|*"no such manifest"*)
        printf 'Immutable Java release tag is unused: %s\n' "$image_ref"
        ;;
      *)
        printf 'Could not verify Java release tag availability: %s\n' "$manifest_output" >&2
        exit 1
        ;;
    esac
  fi
done
