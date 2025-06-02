#!/bin/bash


WAL_FILE_PATH="$1"
WAL_FILE_NAME="$2"
LOG_FILE="/var/log/wal-g/archive.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ARCHIVE] $1" >> "$LOG_FILE"
}

if [ ! -f "$WAL_FILE_PATH" ]; then
    log_message "ERROR: WAL file does not exist: $WAL_FILE_PATH"
    exit 1
fi

log_message "Archiving $WAL_FILE_NAME"

if timeout 300 envdir /etc/wal-g/env /usr/local/bin/wal-g wal-push "$WAL_FILE_PATH" 2>> "$LOG_FILE"; then
    log_message "Successfully archived $WAL_FILE_NAME"
    exit 0
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        log_message "ERROR: Archive timeout for $WAL_FILE_NAME"
    else
        log_message "ERROR: Archive failed for $WAL_FILE_NAME (exit code: $EXIT_CODE)"
    fi
    exit 1
fi