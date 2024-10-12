#!/bin/bash
#  ***************************************************************************
#  *   aws_bkup_wiki.sh                                                      *
#  *                                                                         *
#  *   Copyright (C) 2024 by Jan Dolstra                                     *
#  *   dev@jandnet.nl                                                        *
#  *                                                                         *
#  *   This program is free software; you can redistribute it and/or modify  *
#  *   it under the terms of the GNU General Public License as published by  *
#  *   the Free Software Foundation; either version 3 of the License, or     *
#  *   (at your option) any later version.                                   *
#  *                                                                         *
#  *   This program is distributed in the hope that it will be useful,       *
#  *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
#  *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the          *
#  *   GNU General Public License for more details.                          *
#  *                                                                         *
#  *   You should have received a copy of the GNU General Public License     *
#  *   along with this program; if not, write to the                         *
#  *   Free Software Foundation, Inc.,                                       *
#  *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
#  ***************************************************************************/

# Configuration

# Load configuration from the config file
CONFIG_FILE="$(dirname "$0")/aws_bkup_wiki.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

BACKUP_DIR="$(dirname "$0")/mediawiki_backup"
LAST_BACKUP_INFO="$BACKUP_DIR/last_backup_info.txt"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="mediawiki_backup_$TIMESTAMP.sql"
ZIP_NAME="mediawiki_backup_$TIMESTAMP.zip"  # Zip file name
MYSQLDUMP="$BACKUP_DIR/$BACKUP_NAME"
ZIP_FILE="$BACKUP_DIR/$ZIP_NAME"  # Full path to the zip file

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Get the latest modification timestamp of the MediaWiki tables
LAST_MODIFIED=$(mysql -u $DB_USER -p$DB_PASS -e "SELECT MAX(UNIX_TIMESTAMP(update_time)) FROM information_schema.tables WHERE table_schema='$DB_NAME';" | tail -n 1)
echo "Last modified: $LAST_MODIFIED"

# Read the last backup's modification timestamp from the stored file
if [ -f $LAST_BACKUP_INFO ]; then
  LAST_BACKUP_TIMESTAMP=$(cat $LAST_BACKUP_INFO)
else
  LAST_BACKUP_TIMESTAMP=0
fi

# Check if the database has changed
if [ "$LAST_MODIFIED" -gt "$LAST_BACKUP_TIMESTAMP" ]; then
  echo "New changes detected, proceeding with the backup..."

  # Dump the MediaWiki database
  mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $MYSQLDUMP
  echo "MediaWiki database dump created: $MYSQLDUMP"

  # Create a zip archive containing the SQL dump
  zip -j "$ZIP_FILE" "$MYSQLDUMP"
  echo "Database backup zipped: $ZIP_FILE"

  # Upload the zip archive to S3
  echo "Uploading zip database backup to S3..."
  aws s3 cp "$ZIP_FILE" s3://$S3_BUCKET/$(basename "$ZIP_FILE")

  # Save the latest modification timestamp to the file
  echo $LAST_MODIFIED > $LAST_BACKUP_INFO

  # Send email notification for new backup
  echo "A new MediaWiki database backup ($ZIP_NAME) has been created and uploaded to S3." | mail -s "New MediaWiki backup created" $ADMIN_EMAIL

  # Cleanup the SQL dump
  rm "$MYSQLDUMP"

else
  echo "No changes detected, skipping backup."

  # Send email notification for no new backup
  echo "No changes detected in the MediaWiki database; no backup was created." | mail -s "No new MediaWiki backup" $ADMIN_EMAIL
fi
