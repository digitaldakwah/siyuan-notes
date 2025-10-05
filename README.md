# SiYuan Notes - Self-Hosted Deployment

A self-hosted deployment of SiYuan Notes, a privacy-first, decentralized personal knowledge management system.

## Quick Start

To start the SiYuan Notes service, follow these steps:

```bash
cd /home/kopiahhaji/siyuan-notes/compose
docker compose up -d
```

## Access Information

Once the container is running, you can access SiYuan Notes at the following URL:

`http://<docker-vm-ip>:6806`

Replace `<docker-vm-ip>` with the actual IP address of your Docker VM.

## Documentation

Detailed documentation for this deployment can be found in the `docs/` directory:

-   [Deployment Guide](./docs/DEPLOYMENT.md)
-   [Backup and Restore](./docs/BACKUP.md)
-   [Troubleshooting](./docs/TROUBLESHOOTING.md)

## Maintenance

Maintenance scripts are provided in the `scripts/` directory to automate common tasks:

-   `backup.sh`: Performs automated backups.
-   `update.sh`: Updates the SiYuan Notes Docker image.
-   `health-check.sh`: Monitors the health of the service.

## Environment

-   **Location**: Papar, Sabah, Malaysia
-   **Timezone**: Asia/Kuala_Lumpur
-   **Platform**: Digital Dakwah Notes

## Support

For issues related to SiYuan Notes itself, please refer to the official GitHub repository:

-   [SiYuan Notes GitHub](https://github.com/siyuan-note/siyuan)
