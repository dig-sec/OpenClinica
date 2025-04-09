#!/bin/bash
# backup.sh - Backup script for OpenClinica services

# Set the backup directory and timestamp for unique filenames
BACKUP_DIR="/home/clinical/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create the backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Backup directory: $BACKUP_DIR"
echo "Starting backup at $TIMESTAMP..."

# Backup the PostgreSQL database from the "pgs" container using docker-compose
# This creates a SQL dump file with the timestamp in its name.
echo "Backing up PostgreSQL database..."
docker-compose exec pgs pg_dump -U clinica clinica > "$BACKUP_DIR/clinica_backup_$TIMESTAMP.sql"
if [ $? -eq 0 ]; then
  echo "PostgreSQL backup successful: clinica_backup_$TIMESTAMP.sql"
else
  echo "Error: PostgreSQL backup failed."
fi

# Backup the ocdb-data volume using a temporary alpine container
echo "Backing up the ocdb-data volume..."
docker run --rm \
  -v ocdb-data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czvf /backup/ocdb-data_$TIMESTAMP.tar.gz -C /data .
if [ $? -eq 0 ]; then
  echo "ocdb-data backup successful: ocdb-data_$TIMESTAMP.tar.gz"
else
  echo "Error: ocdb-data backup failed."
fi

# Backup the oc-data volume using a temporary alpine container
echo "Backing up the oc-data volume..."
docker run --rm \
  -v oc-data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czvf /backup/oc-data_$TIMESTAMP.tar.gz -C /data .
if [ $? -eq 0 ]; then
  echo "oc-data backup successful: oc-data_$TIMESTAMP.tar.gz"
else
  echo "Error: oc-data backup failed."
fi

echo "Backup process completed at $(date +"%Y%m%d_%H%M%S"). All files are stored in $BACKUP_DIR."
