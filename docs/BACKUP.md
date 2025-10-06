# Backup and Restore Guide

This document outlines the procedures for backing up and restoring your SiYuan Notes data.

## Automated Backups

### Manual Backup

You can trigger a backup at any time by running the `backup.sh` script.

-   **Run a standard backup:**
    The script will create a timestamped backup file in the `backups/` directory.
    ```bash
    cd /home/kopiahhaji/siyuan-notes && ./scripts/backup.sh
    ```

-   **Run a backup with a custom name:**
    You can provide an optional argument to specify the backup filename.
    ```bash
    ./scripts/backup.sh my-important-backup
    ```

### Scheduled Backups (Cron)

For automated backups, you can set up a cron job.

1.  Open your crontab for editing:
    ```bash
    crontab -e
    ```

2.  Add the following line to schedule a backup every day at 3:00 AM. The output will be logged to `/home/kopiahhaji/siyuan-notes/data/logs/cron-backup.log`.

    ```crontab
    0 3 * * * /home/kopiahhaji/siyuan-notes/scripts/backup.sh >> /home/kopiahhaji/siyuan-notes/data/logs/cron-backup.log 2>&1
    ```

## Restore from Backup

### List Available Backups

To see all the backup archives you have created, list the contents of the `backups/` directory.

```bash
ls -lh /home/kopiahhaji/siyuan-notes/backups/
```
This will show you the filenames, sizes, and creation dates, helping you choose which one to restore.

### Restore Process

**Warning:** The restore process is destructive. It will completely replace your current SiYuan workspace and configuration with the contents of the backup file. A safety backup of the current data is created automatically.

1.  **Run the restore script:**
    Execute the `restore.sh` script, providing the full path to the backup archive you wish to restore.

    ```bash
    ./scripts/restore.sh /home/kopiahhaji/siyuan-notes/backups/siyuan-backup-20251006_010630.tar.gz
    ```

2.  **Confirm the operation:**
    You will be prompted to type `yes` to confirm that you want to proceed with the data replacement.

3.  **Verify the restore:**
    After the script completes, access your SiYuan instance to ensure your data has been restored correctly. You can also check the container's health:
    ```bash
    ./scripts/health-check.sh
    ```

## Backup to External Storage

It is highly recommended to copy your backups to a separate physical location (e.g., a NAS, a different server, or cloud storage).

### Sync to NAS

You can use `rsync` to synchronize your local backup directory with a remote Network Attached Storage (NAS) device.

```bash
rsync -avz /home/kopiahhaji/siyuan-notes/backups/ user@nas-ip:/path/to/siyuan/backups/
```

### Cloud Backup with rclone

`rclone` is an excellent tool for syncing files to various cloud storage providers (Google Drive, S3, Dropbox, etc.).

1.  **Configure rclone:**
    Run `rclone config` to set up a new remote connection to your cloud provider.

2.  **Sync backups:**
    Use a command like the following to sync your backups to a remote named `gdrive`:
    ```bash
    rclone sync /home/kopiahhaji/siyuan-notes/backups/ gdrive:SiYuanBackups --progress
    ```

## Backup Retention

-   **Default Retention:** The `backup.sh` script will automatically delete any backup archives and their corresponding `.sha256` checksum files that are older than 30 days.

-   **Configuration:** You can change the retention period by setting the `BACKUP_RETENTION_DAYS` variable in the `compose/.env` file.
    ```env
    BACKUP_RETENTION_DAYS=90 # Keep backups for 90 days
    ```

## Disaster Recovery

In a complete system failure where the VM is lost, you can recover your SiYuan instance using an offsite backup.

1.  **Prerequisites:**
    -   A new Docker environment.
    -   A copy of your `siyuan-notes` project directory (cloned from Git).
    -   A copy of your backup archives from external storage.

2.  **Steps:**
    -   Clone the Git repository to the new machine.
    -   Copy your backup archives into the `backups/` directory.
    -   Create and populate your `compose/.env` file.
    -   Run the restore script with the desired backup file.
    -   Start the stack with `docker compose up -d`.

3.  **Verification:**
    -   Thoroughly check your notes and assets within the SiYuan UI to ensure data integrity.
