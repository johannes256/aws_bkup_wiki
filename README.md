# AWS MediaWiki Backup Script

## Overview

The `aws_bkup_wiki.sh` script is designed to automate the backup of a MediaWiki database. It checks if the database has been modified since the last backup, and if changes are detected, it creates a SQL dump, compresses it into a ZIP file, and uploads it to an AWS S3 bucket. Email notifications are sent to the administrator whether a backup was created or skipped due to no changes.

## Features

- **Database Change Detection**: The script checks for modifications in the database before performing the backup to avoid unnecessary dumps.
- **Automated Backup**: Backs up the MediaWiki database by creating a SQL dump and zipping it.
- **AWS S3 Integration**: Uploads the compressed database backup to a specified AWS S3 bucket.
- **Email Notifications**: Sends email notifications after each run, indicating whether a backup was created or skipped.
- **Efficient Cleanup**: Automatically cleans up the SQL dump after backup completion.

## Requirements

- AWS CLI configured with proper credentials
- `zip` command installed
- A configured mail system for sending notifications

## Installation

1. **Clone or Download the Script:**

   Download the `aws_bkup_wiki.sh` script and place it in a directory on your server.

2. **Configure AWS CLI:**

   Make sure that the AWS CLI is installed and configured on your system. Run the following command to configure it:

   ```bash
   aws configure
   ```

   You will need to provide your AWS Access Key, Secret Key, region, and output format.

3. **Install Required Packages:**

   Ensure that `mysqldump`, `zip`, and `mail` utilities are installed on your system.   

4. **Create Configuration File:**

   Create a configuration file named `aws_bkup_wiki.conf` in the same directory as the script. This file should contain the necessary configuration parameters for the script:

   ```bash
   # aws_bkup_wiki.conf

   DB_USER="your_db_username"
   DB_PASS="your_db_password"
   DB_NAME="mediawiki_database_name"
   S3_BUCKET="your_s3_bucket_name"
   ADMIN_EMAIL="admin_email@example.com"
   ```

## Usage

1. **Make the Script Executable:**

   Run the following command to make the script executable:

   ```bash
   chmod +x aws_bkup_wiki.sh
   ```

2. **Run the Script:**

   To run the backup script manually, execute the following command:

   ```bash
   ./aws_bkup_wiki.sh
   ```

   You can also set up a cron job to run this script at regular intervals (e.g., daily). Edit your cron jobs by running `crontab -e` and adding a line like:

   ```bash
   0 2 * * * /path/to/aws_bkup_wiki.sh
   ```

   This will run the script every day at 2:00 AM.

## How It Works

1. The script loads configuration parameters from `aws_bkup_wiki.conf`.
2. It checks if the MediaWiki database has been modified since the last backup.
3. If changes are detected:
   - A SQL dump of the database is created using `mysqldump`.
   - The SQL dump is compressed into a ZIP file.
   - The ZIP file is uploaded to an AWS S3 bucket.
   - The last modification timestamp is updated for future reference.
   - An email is sent to notify that a new backup has been created.
4. If no changes are detected:
   - No backup is created, and an email notification is sent to indicate that no changes were detected.

## File Structure

```
.
├── aws_bkup_wiki.sh           # Main script file
├── aws_bkup_wiki.conf         # Configuration file (you must create this)
├── mediawiki_backup/          # Directory where backups are stored temporarily
└── README.md                  # This readme file
```

## Example

A typical example configuration in `aws_bkup_wiki.conf`:

```bash
DB_USER="wikiuser"
DB_PASS="securepassword"
DB_NAME="wikidb"
S3_BUCKET="my-wiki-backups"
ADMIN_EMAIL="admin@mydomain.com"
```

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](https://www.gnu.org/licenses/gpl-3.0.html) for more information.

## Author

Jan Dolstra (dev@jandnet.nl)
