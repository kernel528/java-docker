FROM kernel528/alpine:3.22.1

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
         ESUM='7f96e41d86e7b01cc95de3ea9d649c93efbbcb5f80b87e0dc32ae9e403e2cdb9'; \
         BINARY_URL='https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.1%2B11/OpenJDK23U-jre_aarch64_alpine-linux_hotspot_23.0.1_11.tar.gz'; \
         ;; \
       x86_64) \
         ESUM='b87e6575d8a0ebd8f1a02e9c75d83775d2e2a2e5e5e14bcb9cfed6d9496f4221'; \
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

# Optional: verify runtime environment
RUN set -eux; \
    echo "Verifying JRE install..."; \
    java -XshowSettings:properties -version | grep 'file.encoding'; \
    java -version; \
    echo "Complete."

COPY --chmod=755 entrypoint.sh /__cacert_entrypoint.sh
ENTRYPOINT ["/__cacert_entrypoint.sh"]

CMD ["java"]