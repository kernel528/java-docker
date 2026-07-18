[![Build Status](http://drone.kernelsanders.biz:8080/api/badges/kernel528/java-docker/status.svg)](http://drone.kernelsanders.biz:8080/kernel528/java-docker)
[![Latest Version](https://img.shields.io/github/v/tag/kernel528/java-docker)](https://github.com/kernel528/java-docker/releases/latest)
[![Docker Image Version (latest jdk semver)](https://img.shields.io/docker/v/kernel528/jdk?sort=semver)](https://hub.docker.com/r/kernel528/jdk)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/kernel528/jdk/jdk-latest)](https://hub.docker.com/r/kernel528/jdk/jdk-latest)
[![Docker Image Version (latest jre semver)](https://img.shields.io/docker/v/kernel528/jre?sort=semver)](https://hub.docker.com/r/kernel528/jre)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/kernel528/jre/jre-latest)](https://hub.docker.com/r/kernel528/jre/jre-latest)


# Java Docker
Source repo to build the JDK and JRE images.

## Tags
- JDK: `kernel528/jdk:jdk-latest` (latest published build)
- JRE: `kernel528/jre:jre-latest`
- Versioned tags are also published (see `.drone.yml` and `VERSION.md`).

## Overview
- Base image: `kernel528/alpine` (https://github.com/kernel528/alpine-docker)
- Upstream reference:
  - JDK: https://github.com/adoptium/containers/blob/main/25/jdk/alpine/3.24/Dockerfile
  - JRE: https://github.com/adoptium/containers/blob/main/25/jre/alpine/3.24/Dockerfile
- The Adoptium alpine Dockerfiles are the primary source for updates.
- Drone builds and publishes images on merge/tag events.

## Build
```
docker build -t kernel528/jdk:jdk-latest -f jdk/Dockerfile .
docker build -t kernel528/jdk:jdk25.0.3-9_3.24.1_1 -f jdk/Dockerfile .
docker build -t kernel528/jre:jre-latest -f jre/Dockerfile .
docker build -t kernel528/jre:jre25.0.3-9_3.24.1_1 -f jre/Dockerfile .
```

## CI tags
Drone publishes tags like:
- `jdk25.0.3-9_3.24.1_1`, `jdk25.0.3-9_3.24.1_1-drone-build-<build>`
- `jre25.0.3-9_3.24.1_1`, `jre25.0.3-9_3.24.1_1-drone-build-<build>`

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

Current base image: `kernel528/alpine:3.24.1_1`.

## CA certificates
- Set `USE_SYSTEM_CA_CERTS=1` to import system and custom certs at startup.
- Mount additional certs to `/certificates/*.crt` when needed.
- `entrypoint.sh` is generated upstream; avoid editing it directly.

## How to use
These images are foundational to Java apps. Use the JDK image if you need compiler/tools. Example:
```
        FROM kernel528/jre:latest

        ENV JARFILE app.jar

        ADD $JARFILE /tmp/$JARFILE
        RUN chmod 755 /tmp/$JARFILE

        ENV JAVA_OPTS=""

        ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /tmp/$JARFILE" ]
```

## Authors
* **kernel528** - (kernel528@gmail.com)
