#!/bin/bash
set -e


mkdir -p /var/log/wal-g
chown postgres:postgres /var/log/wal-g

echo '/var/run/postgresql' > /etc/wal-g/env/PGHOST
echo '5432' > /etc/wal-g/env/PGPORT
echo "${POSTGRES_USER:-postgres}" > /etc/wal-g/env/PGUSER
echo "${POSTGRES_DB:-postgres}" > /etc/wal-g/env/PGDATABASE
echo "${POSTGRES_PASSWORD}" > /etc/wal-g/env/PGPASSWORD

echo "${AWS_ACCESS_KEY_ID}" > /etc/wal-g/env/AWS_ACCESS_KEY_ID
echo "${AWS_SECRET_ACCESS_KEY}" > /etc/wal-g/env/AWS_SECRET_ACCESS_KEY
echo "${AWS_REGION:-us-east-1}" > /etc/wal-g/env/AWS_REGION
echo "${WALG_S3_PREFIX}" > /etc/wal-g/env/WALG_S3_PREFIX

if [ -n "${AWS_ENDPOINT}" ]; then
    echo "${AWS_ENDPOINT}" > /etc/wal-g/env/AWS_ENDPOINT
fi

echo "${WALG_LIBSODIUM_KEY}" > /etc/wal-g/env/WALG_LIBSODIUM_KEY
echo 'hex' > /etc/wal-g/env/WALG_LIBSODIUM_KEY_TRANSFORM
echo "${WALG_COMPRESSION_METHOD:-lz4}" > /etc/wal-g/env/WALG_COMPRESSION_METHOD
echo "${WALG_DELTA_MAX_STEPS:-6}" > /etc/wal-g/env/WALG_DELTA_MAX_STEPS
echo "${WALG_UPLOAD_CONCURRENCY:-16}" > /etc/wal-g/env/WALG_UPLOAD_CONCURRENCY
echo "${WALG_DOWNLOAD_CONCURRENCY:-10}" > /etc/wal-g/env/WALG_DOWNLOAD_CONCURRENCY
echo "${WALG_TAR_SIZE_THRESHOLD:-1073741823}" > /etc/wal-g/env/WALG_TAR_SIZE_THRESHOLD
echo "${WALG_UPLOAD_WAL_METADATA:-BULK}" > /etc/wal-g/env/WALG_UPLOAD_WAL_METADATA

chown -R postgres:postgres /etc/wal-g
chmod -R 750 /etc/wal-g
chmod 600 /etc/wal-g/env/*

echo "WAL-G environment configured successfully"
