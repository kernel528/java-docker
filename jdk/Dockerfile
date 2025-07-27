# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#
# Sourced from: https://github.com/adoptium/containers/blob/d7a5038edcd8ab08b0babaeae09d0c097453a023/21/jdk/alpine/Dockerfile

FROM kernel528/alpine:3.22.1

# Set to root user to install packages
USER root

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Default to UTF-8 file.encoding
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN set -eux; \
    apk add --no-cache \
        # font-related packages needed by some Java apps
        fontconfig ttf-dejavu \
        # gnupg required to verify the signature
        gnupg \
        # keep Alpine and OpenJDK CA certificates in sync
        ca-certificates p11-kit-trust \
        # locale support
        musl-locales musl-locales-lang \
        # jlink requires objcopy for Java 13+
        binutils \
        # for time zone data
        tzdata \
        # utilities needed by certificate setup scripts
        coreutils \
        openssl; \
    rm -rf /var/cache/apk/*

ENV JAVA_VERSION=jdk-23.0.1+11

RUN set -eux; \
    ARCH="$(apk --print-arch)"; \
    case "${ARCH}" in \
       aarch64) \
         ESUM='ebdd6602d27bd7535bf06f21e8a0c3d563be7b790a90bef00cb6ac4123c66f86'; \
         BINARY_URL='https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.1%2B11/OpenJDK23U-jdk_aarch64_alpine-linux_hotspot_23.0.1_11.tar.gz'; \
         ;; \
       x86_64) \
         ESUM='4c37a9e885c4e099b049c3ba9baa073de1525e28cd5ffca016c5c5bd7ed385a6'; \
         BINARY_URL='https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.1%2B11/OpenJDK23U-jdk_x64_alpine-linux_hotspot_23.0.1_11.tar.gz'; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    wget -O /tmp/openjdk.tar.gz "${BINARY_URL}"; \
    wget -O /tmp/openjdk.tar.gz.sig "${BINARY_URL}.sig"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 3B04D753C9050D9A5D343F39843C48A565F8F04B; \
    gpg --batch --verify /tmp/openjdk.tar.gz.sig /tmp/openjdk.tar.gz; \
    rm -f /tmp/openjdk.tar.gz.sig; \
    rm -rf "$GNUPGHOME" || true; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p "$JAVA_HOME"; \
    tar --extract \
        --file /tmp/openjdk.tar.gz \
        --directory "$JAVA_HOME" \
        --strip-components 1 \
        --no-same-owner; \
    rm -f /tmp/openjdk.tar.gz "$JAVA_HOME/lib/src.zip"

RUN set -eux; \
    echo "Verifying install ..."; \
    fileEncoding="$(echo 'System.out.println(System.getProperty(\"file.encoding\"))' | jshell -s -)"; \
    [ "$fileEncoding" = 'UTF-8' ]; \
    rm -rf ~/.java; \
    echo "javac --version"; javac --version; \
    echo "java --version"; java --version; \
    echo "Complete."

COPY --chmod=755 entrypoint.sh /__cacert_entrypoint.sh
ENTRYPOINT ["/__cacert_entrypoint.sh"]

CMD ["jshell"]