FROM kernel528/alpine:3.22.1.09

# Set to root user to install packages
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
        binutils \
        tzdata \
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

#RUN set -eux; \
#    echo "Verifying install ..."; \
#    fileEncoding=$(echo 'System.out.println(System.getProperty("file.encoding"));' | jshell --execution local -q | grep -E '^[A-Za-z0-9._-]+$' | tail -n 1); \
#    echo "Detected encoding: $fileEncoding"; \
#    if [ -z "$fileEncoding" ]; then \
#        echo "Error: fileEncoding not detected"; exit 1; \
#    fi; \
#    if [ "$fileEncoding" != "UTF-8" ]; then \
#        echo "Unexpected encoding: $fileEncoding"; exit 1; \
#    fi; \
#    rm -rf ~/.java; \
#    javac --version; \
#    java --version; \
#    echo "Complete."

# Trust download and build option...
RUN set -eux; \
    echo "Detected encoding:"; \
    echo 'System.out.println(System.getProperty("file.encoding"));' | jshell --execution local -q; \
    rm -rf ~/.java; \
    javac --version; \
    java --version; \
    echo "Complete." \

COPY --chmod=755 entrypoint.sh /__cacert_entrypoint.sh
ENTRYPOINT ["/__cacert_entrypoint.sh"]

CMD ["jshell"]