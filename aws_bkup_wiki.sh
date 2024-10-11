#!/bin/bash

# Configuration
S3_BUCKET="my-wiki-backups"
MEDIAWIKI_PATH="/var/www/mediawiki"
DB_NAME="wikidb"
DB_USER="wikiuser"
DB_PASS="securepassword"
BACKUP_DIR="/home/johannes/mediawiki_backup"
LAST_BACKUP_MD5="$BACKUP_DIR/last_backup.md5"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="mediawiki_backup_$TIMESTAMP"
BACKUP_TAR="$BACKUP_DIR/$BACKUP_NAME.tar.gz"
MYSQLDUMP="$BACKUP_DIR/$BACKUP_NAME.sql"

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Dump the MediaWiki database
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $MYSQLDUMP

# Archive MediaWiki files and the database dump
tar -czf $BACKUP_TAR -C $MEDIAWIKI_PATH . -C $BACKUP_DIR $(basename $MYSQLDUMP)

# Generate MD5 checksum of the new backup
NEW_MD5=$(md5sum $BACKUP_TAR | awk '{ print $1 }')

# Compare with the last backup MD5 checksum
if [ -f $LAST_BACKUP_MD5 ]; then
  OLD_MD5=$(cat $LAST_BACKUP_MD5)
else
  OLD_MD5=""
fi

if [ "$NEW_MD5" != "$OLD_MD5" ]; then
  # If the MD5 checksums differ, upload the new backup to S3
  echo "New changes detected, uploading backup to S3..."
  aws s3 cp $BACKUP_TAR s3://$S3_BUCKET/$BACKUP_NAME.tar.gz
  
  # Save the new MD5 checksum
  echo $NEW_MD5 > $LAST_BACKUP_MD5

  # Remove old backup files to save space
  rm $MYSQLDUMP
else
  echo "No changes detected, skipping backup."
  
  # Cleanup
  rm $MYSQLDUMP
  rm $BACKUP_TAR
fi
