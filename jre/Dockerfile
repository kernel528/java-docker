FROM kernel528/alpine:3.22.1.09

USER root

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN set -eux; \
    apk add --no-cache \
        fontconfig ttf-dejavu \
        gnupg \
        ca-certificates p11-kit-trust \
        musl-locales musl-locales-lang \
        tzdata \
        coreutils \
        openssl; \
    rm -rf /var/cache/apk/*

ENV JAVA_VERSION=jre-23.0.1+11

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
    rm -f /tmp/openjdk.tar.gz

RUN set -eux; \
    echo "Verifying JRE install..."; \
    java -XshowSettings:properties -version > /tmp/java-settings.txt 2>&1 || true; \
    grep 'file.encoding' /tmp/java-settings.txt; \
    java -version; \
    echo "Complete."

COPY --chmod=755 entrypoint.sh /__cacert_entrypoint.sh
ENTRYPOINT ["/__cacert_entrypoint.sh"]

CMD ["java"]