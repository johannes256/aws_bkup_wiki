#!/bin/bash

# Configuration
S3_BUCKET="my-wiki-backups"
DB_NAME="wikidb"
DB_USER="wikiuser"
DB_PASS="securepassword"
BACKUP_DIR="$(dirname "$0")/mediawiki_backup"
LAST_BACKUP_MD5="$BACKUP_DIR/last_backup.md5"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="mediawiki_backup_$TIMESTAMP.sql"
ZIP_NAME="mediawiki_backup_$TIMESTAMP.zip"  # Zip file name
MYSQLDUMP="$BACKUP_DIR/$BACKUP_NAME"
ZIP_FILE="$BACKUP_DIR/$ZIP_NAME"  # Full path to the zip file

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Dump the MediaWiki database
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $MYSQLDUMP
echo "MediaWiki database dump created: $MYSQLDUMP"

# Create a zip archive containing the SQL dump
zip -j "$ZIP_FILE" "$MYSQLDUMP"
echo "Database backup zipped: $ZIP_FILE"

# Generate MD5 checksum of the zip backup
NEW_MD5=$(md5sum "$ZIP_FILE" | awk '{ print $1 }')

# Compare with the last backup MD5 checksum
if [ -f $LAST_BACKUP_MD5 ]; then
  OLD_MD5=$(cat $LAST_BACKUP_MD5)
else
  OLD_MD5=""
fi

if [ "$NEW_MD5" != "$OLD_MD5" ]; then
  # If the MD5 checksums differ, upload the new zip backup to S3
  echo "New changes detected, uploading zip database backup to S3..."
  aws s3 cp "$ZIP_FILE" s3://$S3_BUCKET/$(basename "$ZIP_FILE")
  
  # Save the new MD5 checksum
  echo $NEW_MD5 > $LAST_BACKUP_MD5
else
  echo "No changes detected, skipping backup."
  
  # Cleanup
  rm "$ZIP_FILE"
fi

# Cleanup the SQL dump
rm "$MYSQLDUMP"
