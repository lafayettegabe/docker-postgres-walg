#!/bin/bash
set -e


LOG_FILE="/var/log/wal-g/cleanup-cron.log"
RETENTION_DAYS="${WALG_RETENTION_DAYS:-30}"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [CLEANUP-CRON] $1" | tee -a "$LOG_FILE"
}

log_message "Starting automated WAL-G cleanup..."
log_message "Retention policy: $RETENTION_DAYS days (no count limit)"

BACKUP_COUNT_BEFORE=$(envdir /etc/wal-g/env /usr/local/bin/wal-g backup-list 2>/dev/null | wc -l || echo "0")
log_message "Current backup count before cleanup: $BACKUP_COUNT_BEFORE"

CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" '+%Y-%m-%d %H:%M:%S')
log_message "Deleting backups older than: $CUTOFF_DATE"

log_message "Deleting backups older than $RETENTION_DAYS days..."
if envdir /etc/wal-g/env /usr/local/bin/wal-g delete before FIND_FULL "$CUTOFF_DATE" --confirm 2>> "$LOG_FILE"; then
    log_message "Time-based backup cleanup completed"
else
    log_message "WARNING: Time-based backup cleanup failed or no backups to delete"
fi

log_message "Cleaning obsolete WAL files..."
if envdir /etc/wal-g/env /usr/local/bin/wal-g delete garbage ARCHIVES --confirm 2>> "$LOG_FILE"; then
    log_message "WAL cleanup completed"
else
    log_message "WARNING: WAL cleanup failed or no WAL files to clean"
fi

log_message "Cleaning local log files older than $RETENTION_DAYS days..."
find /var/log/wal-g -name "*.log" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

BACKUP_COUNT_AFTER=$(envdir /etc/wal-g/env /usr/local/bin/wal-g backup-list 2>/dev/null | wc -l || echo "0")
DELETED_BACKUPS=$((BACKUP_COUNT_BEFORE - BACKUP_COUNT_AFTER))

log_message "Cleanup completed:"
log_message "- Backups before cleanup: $BACKUP_COUNT_BEFORE"
log_message "- Backups after cleanup: $BACKUP_COUNT_AFTER"
log_message "- Backups deleted: $DELETED_BACKUPS"

if [ "$BACKUP_COUNT_AFTER" -gt 0 ]; then
    log_message "Current backup storage summary:"
    envdir /etc/wal-g/env /usr/local/bin/wal-g backup-list --pretty 2>/dev/null | head -10 >> "$LOG_FILE" || true
fi

log_message "Automated cleanup completed"