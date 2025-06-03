# 🐘 PostgreSQL + WAL-G Docker Image

<p align="center">
  <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"></a>
  <a href="https://www.postgresql.org/"><img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"></a>
  <a href="https://aws.amazon.com/s3/"><img src="https://img.shields.io/badge/Amazon_AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS S3"></a>
  <a href="https://www.linux.org/"><img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux"></a>
  <a href="https://www.gnu.org/software/bash/"><img src="https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="Shell Script"></a>
</p>

<p align="center">
  <a href="https://github.com/lafayettegabe/wald"><img src="https://img.shields.io/badge/Multi--Architecture-AMD64%20%7C%20ARM64-blue?style=flat-square" alt="Multi-Architecture"></a>
  <a href="https://github.com/lafayettegabe/wald"><img src="https://img.shields.io/badge/Automated-Backups-green?style=flat-square" alt="Automated Backups"></a>
  <a href="https://github.com/lafayettegabe/wald"><img src="https://img.shields.io/badge/S3-Compatible-orange?style=flat-square" alt="S3 Compatible"></a>
  <a href="https://github.com/lafayettegabe/wald"><img src="https://img.shields.io/badge/Email-Notifications-purple?style=flat-square" alt="Email Notifications"></a>
</p>

> 🚀 **Production-ready PostgreSQL with automated WAL-G backups to S3-compatible storage**

A Docker image that combines PostgreSQL with WAL-G for automated, encrypted backups to S3-compatible storage. Features include automatic WAL archiving, scheduled incremental and full backups, intelligent cleanup, and email notifications.

## ✨ Features

- 🔄 **Automated Backup Scheduling**
  - Incremental backups every 2 hours
  - Full backups daily at 4 AM
  - Automated cleanup daily at 5 AM
- 🏗️ **Multi-Architecture Support** - AMD64 and ARM64
- 🔐 **Encryption** - Built-in libsodium encryption
- 📧 **Email Notifications** - Success/failure notifications
- 🗄️ **S3-Compatible Storage** - AWS S3, MinIO, etc.
- 📊 **Comprehensive Logging** - Detailed backup logs
- ⚡ **Optimized Performance** - Tuned PostgreSQL parameters
- 🔧 **Zero Configuration** - Works out of the box

## 🚀 Quick Start

### 1. Create Environment File

Create a `.env` file with your configuration:

```bash
# PostgreSQL Configuration
POSTGRES_DB=myapp
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secure_password

# AWS/S3 Configuration
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
WALG_S3_PREFIX=s3://your-bucket/postgres-backups

# WAL-G Configuration
WALG_LIBSODIUM_KEY=your_64_character_hex_encryption_key_here_1234567890abcdef
WALG_RETENTION_DAYS=30

# Optional: Custom S3 Endpoint (for MinIO, etc.)
# AWS_ENDPOINT=https://your-minio-endpoint.com

# Optional: Email Notifications
# WALG_NOTIFICATION_EMAIL=admin@yourcompany.com
```

### 2. Run with Docker Compose

```yaml
services:
  postgres:
    image: lafayettegabe/wald:latest
    container_name: postgres-walg
    restart: unless-stopped
    ports:
      - "5432:5432"
    env_file:
      - .env
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
      - ./data/logs:/var/log/wal-g
```

```bash
docker-compose up -d
```

### 3. Verify Backup Setup

```bash
# Check container logs
docker logs postgres-walg

# Check backup status
docker exec postgres-walg su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-list"

# View backup logs
docker exec postgres-walg tail -f /var/log/wal-g/backup-cron.log
```

## 📋 Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS/S3 access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS/S3 secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `WALG_S3_PREFIX` | S3 backup location | `s3://my-bucket/postgres-backups` |
| `WALG_LIBSODIUM_KEY` | 64-char hex encryption key | `64_character_hex_string_here...` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AWS_REGION` | `us-east-1` | AWS region |
| `AWS_ENDPOINT` | - | Custom S3 endpoint (MinIO, etc.) |
| `WALG_RETENTION_DAYS` | `30` | Backup retention period |
| `WALG_COMPRESSION_METHOD` | `lz4` | Compression method |
| `WALG_AUTOMATED_BACKUPS` | `true` | Enable/disable automated backups |
| `WALG_NOTIFICATION_EMAIL` | - | Email for backup notifications |
| `WALG_UPLOAD_CONCURRENCY` | `16` | Upload concurrency |
| `WALG_DOWNLOAD_CONCURRENCY` | `10` | Download concurrency |

## 🕒 Backup Schedule

The backup schedule is **hardcoded** for reliability and cannot be changed via environment variables:

| Type | Schedule | Description |
|------|----------|-------------|
| **Incremental** | `0 */2 * * *` | Every 2 hours |
| **Full Backup** | `0 4 * * *` | Daily at 4:00 AM |
| **Cleanup** | `0 5 * * *` | Daily at 5:00 AM |

## 🛠️ Manual Operations

### Create Manual Backup

```bash
# Full backup
docker exec postgres-walg su - postgres -c "WALG_DELTA_MAX_STEPS=0 envdir /etc/wal-g/env /usr/local/bin/wal-g backup-push /var/lib/postgresql/data"

# Incremental backup
docker exec postgres-walg su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-push /var/lib/postgresql/data"
```

### List Backups

```bash
# Simple list
docker exec postgres-walg su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-list"

# Detailed view
docker exec postgres-walg su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-list --detail"
```

### Restore Database

```bash
# Stop the container
docker-compose down

# Remove existing data
sudo rm -rf ./data/postgres/*

# Restore from latest backup
docker run --rm \
  --env-file .env \
  -v $(pwd)/data/postgres:/var/lib/postgresql/data \
  lafayettegabe/wald:latest \
  su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-fetch /var/lib/postgresql/data LATEST"

# Start container
docker-compose up -d
```

### Point-in-Time Recovery

```bash
# Restore to specific time
docker run --rm \
  --env-file .env \
  -v $(pwd)/data/postgres:/var/lib/postgresql/data \
  lafayettegabe/wald:latest \
  su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-fetch /var/lib/postgresql/data LATEST"

# Create recovery configuration
echo "restore_command = 'envdir /etc/wal-g/env /usr/local/bin/wal-g wal-fetch %f %p'" > ./data/postgres/recovery.conf
echo "recovery_target_time = '2025-06-02 14:30:00'" >> ./data/postgres/recovery.conf
```

## 📊 Monitoring & Logs

### Log Locations

| Log Type | Location | Description |
|----------|----------|-------------|
| **WAL Archive** | `/var/log/wal-g/archive.log` | WAL file archiving |
| **Backup Cron** | `/var/log/wal-g/backup-cron.log` | Scheduled backups |
| **Cleanup** | `/var/log/wal-g/cleanup-cron.log` | Backup cleanup |
| **Setup** | `/var/log/wal-g/cron-setup.log` | Initial setup |

### View Logs

```bash
# Real-time backup logs
docker exec postgres-walg tail -f /var/log/wal-g/backup-cron.log

# Archive logs
docker exec postgres-walg tail -f /var/log/wal-g/archive.log

# All WAL-G logs
docker exec postgres-walg tail -f /var/log/wal-g/*.log
```

### Health Checks

```bash
# Check PostgreSQL status
docker exec postgres-walg pg_isready -U postgres

# Check latest backup
docker exec postgres-walg su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-list | tail -1"

# Check disk usage
docker exec postgres-walg df -h /var/lib/postgresql/data
```

## 🔧 Advanced Configuration

### Custom PostgreSQL Parameters

The image includes optimized PostgreSQL parameters for backup performance:

```ini
archive_mode = on
archive_command = /scripts/archive-command.sh '%p' '%f'
archive_timeout = 300
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1GB
wal_compression = on
checkpoint_completion_target = 0.7
checkpoint_timeout = 15min
max_wal_size = 2GB
min_wal_size = 1GB
```

### Encryption Key Generation

Generate a secure encryption key:

```bash
# Generate 256-bit key
openssl rand -hex 32
```

### S3 Bucket Policy

Example S3 bucket policy for WAL-G:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT:user/walg-user"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket/*",
        "arn:aws:s3:::your-bucket"
      ]
    }
  ]
}
```

## 🏗️ Building from Source

### Prerequisites

- Docker with Buildx
- Multi-architecture builder

### Build Commands

```bash
# Clone repository
git clone https://github.com/lafayettegabe/wald.git
cd wald

# Build multi-architecture image
chmod +x build.sh
./build.sh
```

### Build Configuration

The build script creates images for:
- `linux/amd64` (Intel/AMD 64-bit)
- `linux/arm64` (ARM 64-bit, Apple Silicon, etc.)

## 🐛 Troubleshooting

### Common Issues

**Backup Fails with Permission Error**
```bash
# Check WAL-G environment permissions
docker exec postgres-walg ls -la /etc/wal-g/env/
```

**WAL Files Not Archiving**
```bash
# Check archive command logs
docker exec postgres-walg tail -20 /var/log/wal-g/archive.log
```

**S3 Connection Issues**
```bash
# Test S3 connectivity
docker exec postgres-walg su - postgres -c "envdir /etc/wal-g/env /usr/local/bin/wal-g backup-list"
```

**Container Won't Start**
```bash
# Check required environment variables
docker-compose config
```

### Debug Mode

Enable verbose logging:

```bash
# Run with debug output
docker run -it --env-file .env lafayettegabe/wald:latest bash
```

## 📚 Documentation

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [WAL-G Documentation](https://wal-g.readthedocs.io/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [WAL-G Team](https://github.com/wal-g/wal-g) for the excellent backup tool
- [PostgreSQL Community](https://www.postgresql.org/) for the amazing database
- [Docker Community](https://www.docker.com/) for containerization platform

---

<p align="center">
  <strong>⭐ Star this repo if it helped you! ⭐</strong>
</p>

<p align="center">
  <a href="https://github.com/lafayettegabe/wald/issues">Report Bug</a> •
  <a href="https://github.com/lafayettegabe/wald/issues">Request Feature</a> •
  <a href="https://github.com/lafayettegabe/wald">View Source</a>
</p>
