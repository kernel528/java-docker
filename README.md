[![Build Status](http://drone.kernelsanders.biz:8080/api/badges/kernel528/java-docker/status.svg)](http://drone.kernelsanders.biz:8080/kernel528/java-docker)
[![Latest Version](https://img.shields.io/github/v/tag/kernel528/java-docker)](https://github.com/kernel528/java-docker/releases/latest)
[![Docker Pulls](https://img.shields.io/docker/pulls/kernel528/java)](https://hub.docker.com/r/kernel528/java)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/kernel528/java/jdk-latest)](https://hub.docker.com/r/kernel528/java/jdk-latest)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/kernel528/java/jre-latest)](https://hub.docker.com/r/kernel528/java/jre-latest)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kernel528/java?sort=semver)](https://hub.docker.com/r/kernel528/java)

# Java Docker
### Source repo to build the JDK and JRE docker images.
- These can be called as such:
  - JDK:  kernel528/jdk:latest
  - JRE:  kernel528/jre:latest

### Comments
- This image uses the kernel528/alpine as the base image (https://github.com/kernel528/alpine-docker)
- This repo is based on:
  - JDK: https://github.com/adoptium/containers/blob/d7a5038edcd8ab08b0babaeae09d0c097453a023/21/jdk/alpine/Dockerfile
  - JRE: https://github.com/adoptium/containers/blob/d7a5038edcd8ab08b0babaeae09d0c097453a023/21/jre/alpine/Dockerfile
- The subfolder 11/jdk and 11/jre from above link as the main source for building purposes.
- Drone is used to automate the build and publish of the docker images.

### How to Update
- Review the available version from the Alpine Linux package site:  
  - Perform a search using:  openjdk*
- If a new version exists, then update the following variables in the respective Dockerfile:
    ```
    JAVA_VERSION
    JAVA_ALPINE_VERSION
    ```

### How To build for JDK
- Clone this repo.
- Execute:  ```docker build -t kernel528/jdk:21 -f ./21/jdk/Dockerfile .```

### How To build for JRE
- Clone this repo.
- Execute ```docker build -t kernel528/jre:21 -f ./21/jre/Dockerfile .```

### Drone Builds
- This repo uses drone to automatically build images when new code is merged.  Refer to the .drone.yml file for details.  
- There are several tags used to differentiate builds.  Refer to the .drone.yml file for details.

### How to use
- These images are foundational to any java apps which require JRE or JDK to run.  If you need the full library set, then use the JDK version.  Example:
```
        FROM kernel528/jre:latest

        ENV JARFILE app.jar

        ADD $JARFILE /tmp/$JARFILE
        RUN chmod 755 /tmp/$JARFILE

        ENV JAVA_OPTS=""

        ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /tmp/$JARFILE" ]
```

### Authors
* **kernel528** - (kernel528@gmail.com)
