#!/bin/bash

# Configuration
S3_BUCKET="my-wiki-backups"
DB_NAME="wikidb"
DB_USER="wikiuser"
DB_PASS="securepassword"
BACKUP_DIR="/home/johannes/mediawiki_backup"
LAST_BACKUP_MD5="$BACKUP_DIR/last_backup.md5"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="mediawiki_backup_$TIMESTAMP.sql"
MYSQLDUMP="$BACKUP_DIR/$BACKUP_NAME"

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Dump the MediaWiki database
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $MYSQLDUMP
echo "MediaWiki database dump created: $MYSQLDUMP"

# Generate MD5 checksum of the new backup
NEW_MD5=$(md5sum $MYSQLDUMP | awk '{ print $1 }')

# Compare with the last backup MD5 checksum
if [ -f $LAST_BACKUP_MD5 ]; then
  OLD_MD5=$(cat $LAST_BACKUP_MD5)
else
  OLD_MD5=""
fi

if [ "$NEW_MD5" != "$OLD_MD5" ]; then
  # If the MD5 checksums differ, upload the new backup to S3
  echo "New changes detected, uploading database backup to S3..."
  aws s3 cp $MYSQLDUMP s3://$S3_BUCKET/$BACKUP_NAME
  
  # Save the new MD5 checksum
  echo $NEW_MD5 > $LAST_BACKUP_MD5
else
  echo "No changes detected, skipping backup."
  
  # Cleanup
  rm $MYSQLDUMP
fi