#!/bin/bash
set -e

LOG_FILE="/var/log/wal-g/cron-setup.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [CRON-SETUP] $1" | tee -a "$LOG_FILE"
}

log_message "Setting up automated WAL-G backup schedule..."

INCREMENTAL_SCHEDULE="0 */2 * * *"     # Every 2 hours - FIXED
FULL_BACKUP_SCHEDULE="0 4 * * *"       # Daily at 4 AM - FIXED  
CLEANUP_SCHEDULE="0 5 * * *"           # Daily at 5 AM - FIXED

RETENTION_DAYS="${WALG_RETENTION_DAYS:-30}"

if [ "${WALG_AUTOMATED_BACKUPS:-true}" = "false" ]; then
    log_message "Automated backups disabled via WALG_AUTOMATED_BACKUPS=false"
    exit 0
fi

log_message "HARDCODED backup schedules:"
log_message "- Incremental backups: $INCREMENTAL_SCHEDULE (every 2 hours)"
log_message "- Full backups: $FULL_BACKUP_SCHEDULE (daily at 4 AM)"
log_message "- Cleanup: $CLEANUP_SCHEDULE (daily at 5 AM)"
log_message "- Retention: $RETENTION_DAYS days"

cat > /tmp/postgres-cron << EOF
# WAL-G Automated Backup Jobs - HARDCODED SCHEDULES

# Incremental backups every 2 hours (FIXED)
0 */2 * * * /scripts/backup-cron.sh incremental >> /var/log/wal-g/incremental-backup.log 2>&1

# Full backup daily at 4 AM (FIXED)
0 4 * * * /scripts/backup-cron.sh full >> /var/log/wal-g/full-backup.log 2>&1

# Cleanup old backups daily at 5 AM (FIXED)
0 5 * * * /scripts/cleanup-cron.sh >> /var/log/wal-g/cleanup-cron.log 2>&1

EOF

crontab -u postgres /tmp/postgres-cron
rm /tmp/postgres-cron

cron

log_message "Automated backup schedule configured successfully with HARDCODED timings"
log_message "Schedule cannot be changed via environment variables"
log_message "- Every 2 hours: Incremental backups"
log_message "- Daily 4 AM: Full backup"
log_message "- Daily 5 AM: Cleanup"