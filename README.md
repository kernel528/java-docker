[![Build Status](https://drone.kernelsanders.biz:8443/api/badges/kernel528/java-docker/status.svg)](https://drone.kernelsanders.biz:8443/kernel528/java-docker)
[![Latest Version](https://img.shields.io/github/v/tag/kernel528/java-docker)](https://github.com/kernel528/java-docker/releases/latest)
[![Docker Image Version (latest jdk semver)](https://img.shields.io/docker/v/kernel528/java?sort=semver&label=JDK)](https://hub.docker.com/r/kernel528/java)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/kernel528/java/jdk-latest)](https://hub.docker.com/r/kernel528/java/jdk-latest)
[![Docker Image Version (latest jre semver)](https://img.shields.io/docker/v/kernel528/java?sort=semver&label=JRE)](https://hub.docker.com/r/kernel528/java)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/kernel528/java/jre-latest)](https://hub.docker.com/r/kernel528/java/jre-latest)


# Java Docker
Source repo to build the JDK and JRE images.

## Tags
- JDK: `kernel528/java:jdk-latest` (latest published build)
- JRE: `kernel528/java:jre-latest`
- Versioned tags are also published (see `.drone.yml` and `VERSION.md`).

## Overview
- Base image: `kernel528/alpine` (https://github.com/kernel528/alpine-docker)
- Upstream reference:
  - JDK: https://github.com/adoptium/containers/blob/main/25/jdk/alpine/3.24/Dockerfile
  - JRE: https://github.com/adoptium/containers/blob/main/25/jre/alpine/3.24/Dockerfile
- The Adoptium alpine Dockerfiles are the primary source for updates.
- Drone builds and publishes images on merge/tag events.

## Repository Relationships and Refresh Policy

This independent repository is coordinated by [`docker-workspace`](https://github.com/kernel528/docker-workspace). Both the JDK and JRE Dockerfiles directly use `kernel528/alpine`; neither image is built from the other. Publish the Alpine tag first, update both Dockerfiles together, validate compilation with the JDK and execution with the JRE, then publish immutable JDK and JRE tags. Update [`docker-swarm`](https://github.com/kernel528/docker-swarm) only where a stack explicitly consumes those tags.

## CI validation and release policy

- Pull requests targeting `25` run rootless exact-image checks for both JDK and JRE; the job receives no registry credentials and publishes nothing.
- Pushes to `25` run rootless validation plus fresh DIND candidate builds; a separate credentialed step publishes unique build-number tags for each image.
- Tags are created manually from reviewed `main`. The tag pipeline freshly builds and smoke-tests both images, checks that both immutable tags are unused, publishes them, then updates `jdk-latest` and `jre-latest` to those tested images.
- Candidate tags are not deployment inputs. JDK and JRE tags are both stored in the consolidated `kernel528/java` repository.
- This repository is public. The rootless validation job runs without credentials inside the isolated guest; PR code therefore executes there with the guest's rootless Podman boundary.
- Add `kernel528/java-docker` to the isolated runner's exact repository allowlist only after reviewing this pipeline. Do not add wildcard repository patterns.

## Build
```
docker build -t kernel528/java:jdk-latest -f jdk/Dockerfile .
docker build -t kernel528/java:jdk25.0.4.1-1_3.24.3_3 -f jdk/Dockerfile .
docker build -t kernel528/java:jre-latest -f jre/Dockerfile .
docker build -t kernel528/java:jre25.0.4.1-1_3.24.3_3 -f jre/Dockerfile .
```

## CI tags
Drone publishes tags like:
- `jdk25.0.4.1-1_3.24.3_3`, `jdk25.0.4.1-1_3.24.3_3-drone-build-<build>`
- `jre25.0.4.1-1_3.24.3_3`, `jre25.0.4.1-1_3.24.3_3-drone-build-<build>`

Source of truth: `.drone.yml`. To list current tags quickly:
```
rg -n "tags:" -n .drone.yml -A 6
```
Or use the helper script:
```
./scripts/list-ci-tags.sh
```

## Update process
- Check for new Temurin/Adoptium releases for alpine.
- Update these in `jdk/Dockerfile` and `jre/Dockerfile`:
  - `JAVA_VERSION`
  - download `BINARY_URL` and `ESUM` values
- If the base image changes, update `FROM kernel528/alpine:<tag>` in both Dockerfiles.
- Keep `.drone.yml`, `README.md`, and `VERSION.md` aligned with the new tags.

Current base image: `kernel528/alpine:3.24.3_3`.

## CA certificates
- Set `USE_SYSTEM_CA_CERTS=1` to import system and custom certs at startup.
- Mount additional certs to `/certificates/*.crt` when needed.
- `entrypoint.sh` is generated upstream; avoid editing it directly.

## How to use
These images are foundational to Java apps. Use the JDK image if you need compiler/tools. Example:
```
        FROM kernel528/java:jre25.0.4.1-1_3.24.3_3

        ENV JARFILE app.jar

        ADD $JARFILE /tmp/$JARFILE
        RUN chmod 755 /tmp/$JARFILE

        ENV JAVA_OPTS=""

        ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /tmp/$JARFILE" ]
```

## Authors
* **kernel528** - (kernel528@gmail.com)
