
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM kernel528/alpine:3.22.0

# Set to root user to install packages
USER root

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Default to UTF-8 file.encoding
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN set -eux; \
    apk add --no-cache \
        # java.lang.UnsatisfiedLinkError: libfontmanager.so: libfreetype.so.6: cannot open shared object file: No such file or directory
        # java.lang.NoClassDefFoundError: Could not initialize class sun.awt.X11FontManager
        # https://github.com/docker-library/openjdk/pull/235#issuecomment-424466077
        fontconfig ttf-dejavu \
        # gnupg required to verify the signature
        gnupg \
        # utilities for keeping Alpine and OpenJDK CA certificates in sync
        # https://github.com/adoptium/containers/issues/293
        ca-certificates p11-kit-trust \
        # locales ensures proper character encoding and locale-specific behaviors using en_US.UTF-8
        musl-locales musl-locales-lang \
        tzdata \
        # Contains `csplit` used for splitting multiple certificates in one file to multiple files, since keytool can
        # only import one at a time.
        coreutils \
        # Needed to extract CN and generate aliases for certificates
        openssl \
    ; \
    rm -rf /var/cache/apk/*

ENV JAVA_VERSION=jdk-23.0.1+11

RUN set -eux; \
    ARCH="$(apk --print-arch)"; \
    case "${ARCH}" in \
       aarch64) \
         ESUM='b56eaedc094cb9107be2d5be9ad34c3dd9492c45aa671d102b5829a488cfc744'; \
         BINARY_URL='https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.1%2B11/OpenJDK23U-jre_aarch64_alpine-linux_hotspot_23.0.1_11.tar.gz'; \
         ;; \
       x86_64) \
         ESUM='38a1b20b5ee8869b20e9f9aefdc91eedf245584d35287842a66540f0745dd3d0'; \
         BINARY_URL='https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.1%2B11/OpenJDK23U-jre_x64_alpine-linux_hotspot_23.0.1_11.tar.gz'; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    wget -O /tmp/openjdk.tar.gz ${BINARY_URL}; \
    wget -O /tmp/openjdk.tar.gz.sig ${BINARY_URL}.sig; \
    export GNUPGHOME="$(mktemp -d)"; \
    # gpg: key 843C48A565F8F04B: "Adoptium GPG Key (DEB/RPM Signing Key) <temurin-dev@eclipse.org>" imported
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 3B04D753C9050D9A5D343F39843C48A565F8F04B; \
    gpg --batch --verify /tmp/openjdk.tar.gz.sig /tmp/openjdk.tar.gz; \
    rm -r "${GNUPGHOME}" /tmp/openjdk.tar.gz.sig; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p "$JAVA_HOME"; \
    tar --extract \
        --file /tmp/openjdk.tar.gz \
        --directory "$JAVA_HOME" \
        --strip-components 1 \
        --no-same-owner \
    ; \
    rm -f /tmp/openjdk.tar.gz ${JAVA_HOME}/lib/src.zip;

RUN set -eux; \
    echo "Verifying install ..."; \
    echo "java --version"; java --version; \
    echo "Complete."
COPY --chmod=755 entrypoint.sh /__cacert_entrypoint.sh
ENTRYPOINT ["/__cacert_entrypoint.sh"]