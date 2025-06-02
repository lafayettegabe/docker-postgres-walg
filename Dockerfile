FROM postgres:16

LABEL maintainer="gabriel.lafayette@proton.me"
LABEL description="PostgreSQL 16 with WAL-G backup support"
LABEL version="1.0.0"

ARG TARGETARCH
ARG TARGETOS
ARG TARGETPLATFORM

ENV WALG_VERSION=v3.0.7
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    daemontools \
    cron \
    gettext-base \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) \
            WALG_ARCH="amd64"; \
            WALG_FILE="wal-g-pg-ubuntu-20.04-amd64.tar.gz"; \
            ;; \
        arm64) \
            WALG_ARCH="aarch64"; \
            WALG_FILE="wal-g-pg-ubuntu-20.04-aarch64.tar.gz"; \
            ;; \
        *) \
            echo "Unsupported architecture: ${TARGETARCH}"; \
            exit 1; \
            ;; \
    esac; \
    echo "Downloading WAL-G for ${TARGETARCH} (${WALG_ARCH})..."; \
    wget "https://github.com/wal-g/wal-g/releases/download/${WALG_VERSION}/${WALG_FILE}" \
    && tar -zxvf "${WALG_FILE}" \
    && mv "wal-g-pg-ubuntu-20.04-${WALG_ARCH}" /usr/local/bin/wal-g \
    && chmod +x /usr/local/bin/wal-g \
    && rm "${WALG_FILE}" \
    && echo "WAL-G ${WALG_VERSION} installed for ${TARGETARCH}"

RUN /usr/local/bin/wal-g --version

RUN mkdir -p /etc/wal-g/env \
    && mkdir -p /var/log/wal-g \
    && mkdir -p /scripts \
    && mkdir -p /var/spool/cron/crontabs \
    && chown -R postgres:postgres /etc/wal-g \
    && chown -R postgres:postgres /var/log/wal-g \
    && chown -R postgres:postgres /scripts

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

COPY scripts/entrypoint.sh /usr/local/bin/docker-entrypoint-walg.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-walg.sh

EXPOSE 5432

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-walg.sh"]
CMD ["postgres"]