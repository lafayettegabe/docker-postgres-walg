#!/bin/bash
set -e


log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WALG-ENTRYPOINT] $1"
}

log_message "Starting PostgreSQL with WAL-G backup support..."

if [ "$1" != "postgres" ]; then
    log_message "Not starting PostgreSQL server, passing through to original entrypoint..."
    exec docker-entrypoint.sh "$@"
fi

required_vars=(
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "WALG_S3_PREFIX"
    "WALG_LIBSODIUM_KEY"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    log_message "ERROR: Missing required WAL-G environment variables: ${missing_vars[*]}"
    log_message "Please set these environment variables and restart the container"
    exit 1
fi

log_message "Configuring WAL-G environment..."
/scripts/init-walg.sh

log_message "Setting up automated backup schedule..."
/scripts/setup-cron.sh

log_message "Starting PostgreSQL with WAL-G archiving enabled..."

shift
postgres_args=(
    "-c" "archive_mode=on"
    "-c" "archive_command=/scripts/archive-command.sh '%p' '%f'"
    "-c" "archive_timeout=300"
    "-c" "wal_level=replica"
    "-c" "max_wal_senders=10"
    "-c" "wal_keep_size=1GB"
    "-c" "wal_compression=on"
    "-c" "checkpoint_completion_target=0.7"
    "-c" "checkpoint_timeout=15min"
    "-c" "max_wal_size=2GB"
    "-c" "min_wal_size=1GB"
    "$@"
)

docker-entrypoint.sh postgres "${postgres_args[@]}" &
POSTGRES_PID=$!

check_postgres_ready() {
    for i in {1..60}; do
        if pg_isready -U "${POSTGRES_USER:-postgres}" >/dev/null 2>&1; then
            return 0
        fi
        sleep 2
    done
    return 1
}

create_initial_backup() {
    log_message "Creating initial backup..."
    
    DB_NAME="${POSTGRES_DB:-postgres}"
    DB_SIZE=$(psql -U "${POSTGRES_USER:-postgres}" -d "$DB_NAME" -t -c "SELECT pg_size_pretty(pg_database_size('$DB_NAME'));" 2>/dev/null | xargs || echo "Unknown")
    
    log_message "Database: $DB_NAME"
    log_message "Database size: $DB_SIZE"
    
    BACKUP_START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    BACKUP_START_EPOCH=$(date +%s)
    
    if su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-push /var/lib/postgresql/data" 2>/var/log/wal-g/initial-backup.log; then
        BACKUP_END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
        BACKUP_END_EPOCH=$(date +%s)
        BACKUP_DURATION=$((BACKUP_END_EPOCH - BACKUP_START_EPOCH))
        
        BACKUP_NAME=$(su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-list --detail --json" 2>/dev/null | tail -1 | grep -o '"backup_name":"[^"]*"' | cut -d'"' -f4 || echo "Unknown")
        
        log_message "✅ Initial backup completed successfully!"
        log_message "   Backup name: $BACKUP_NAME"
        log_message "   Duration: ${BACKUP_DURATION} seconds"
        log_message "   Started: $BACKUP_START_TIME"
        log_message "   Completed: $BACKUP_END_TIME"
        log_message "   Size: $DB_SIZE"
        
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INITIAL-BACKUP] Initial backup completed: $BACKUP_NAME (${BACKUP_DURATION}s)" >> /var/log/wal-g/backup-cron.log
    else
        log_message "❌ Initial backup failed!"
        log_message "   Check logs: /var/log/wal-g/initial-backup.log"
        log_message "   Container will continue running, but manual backup may be needed"
        
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INITIAL-BACKUP] Initial backup failed - check /var/log/wal-g/initial-backup.log" >> /var/log/wal-g/backup-cron.log
    fi
}

(
    log_message "Waiting for PostgreSQL to be ready..."
    
    if check_postgres_ready; then
        log_message "PostgreSQL is ready!"
        
        sleep 3
        
        EXISTING_BACKUPS=$(su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-list" 2>/dev/null | wc -l || echo "0")
        
        if [ "$EXISTING_BACKUPS" -eq 0 ]; then
            log_message "No existing backups found, creating initial backup..."
            create_initial_backup
        else
            log_message "Found $EXISTING_BACKUPS existing backup(s), skipping initial backup"
        fi
    else
        log_message "❌ PostgreSQL failed to become ready within 2 minutes"
        log_message "   Container will continue running, but initial backup was skipped"
    fi
) &

wait $POSTGRES_PID