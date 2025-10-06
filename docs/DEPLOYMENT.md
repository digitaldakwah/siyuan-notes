# SiYuan Deployment Guide

This guide provides instructions for deploying, managing, and maintaining the SiYuan Notes service using the provided Docker Compose setup.

## Quick Start

To get the SiYuan service running quickly, follow these steps:

1.  **Navigate to the compose directory:**
    ```bash
    cd /home/kopiahhaji/siyuan-notes/compose/
    ```

2.  **Start the services in detached mode:**
    ```bash
    docker compose up -d
    ```

3.  **Check the status of the containers:**
    The `siyuan-app` container should show a `running (healthy)` status after a minute.
    ```bash
    docker compose ps
    ```

4.  **View live logs:**
    To monitor the application's logs in real-time, use:
    ```bash
    docker compose logs -f siyuan
    ```

## Accessing SiYuan

-   **Local Access:** Once the container is running, you can access SiYuan directly in your web browser at `http://<DOCKER_VM_IP>:${SIYUAN_PORT}`. The default port is `6806`.
    ```
    http://192.168.1.100:6806
    ```

-   **Authentication:** You will be prompted for an access authentication code. This code is defined by the `SIYUAN_ACCESS_AUTH_CODE` variable in the `compose/.env` file.

-   **With Nginx Proxy (Optional):** If you have enabled the `proxy` profile and configured Nginx and DNS, you can access SiYuan securely via a domain name:
    ```
    https://notes.yourdomain.com
    ```

## Directory Structure

The project is organized into the following directories:

```
/home/kopiahhaji/siyuan-notes/
├─── compose/       # Docker Compose files and environment variables (.env)
├─── data/          # Persistent application data
│    ├─── config/   # SiYuan configuration files
│    ├─── logs/     # Application-level logs
│    └─── workspace/ # Your notes and assets
├─── backups/       # Default location for backup archives
├─── docs/          # Project documentation
├─── nginx/         # Nginx configuration, logs, and SSL certificates
└─── scripts/       # Maintenance and automation scripts (backup, restore, etc.)
```

## Configuration

-   **Primary Configuration:** All runtime configurations are managed in the `compose/.env` file. To customize your deployment, copy `compose/.env.example` to `compose/.env` and edit the values.

-   **Common Settings to Adjust:**
    -   `SIYUAN_PORT`: The external port to access SiYuan.
    -   `TZ`: Your local timezone (e.g., `Asia/Kuala_Lumpur`).
    -   `PUID`/`PGID`: User and group IDs for file permissions.
    -   `CPU_LIMIT`/`MEMORY_LIMIT`: Resource allocation for the container.
    -   `SIYUAN_ACCESS_AUTH_CODE`: Your secret access password.

-   **Applying Changes:** After modifying the `.env` file, you must recreate the containers for the changes to take effect:
    ```bash
    cd /home/kopiahhaji/siyuan-notes/compose/
    docker compose down
    docker compose up -d
    ```

## Resource Management

-   **Checking Usage:** To view the live resource consumption (CPU, Memory) of the SiYuan container, use:
    ```bash
    docker stats siyuan-app
    ```

-   **Adjusting Limits:** You can adjust the maximum CPU and memory the container is allowed to use by changing these variables in `compose/.env`:
    -   `CPU_LIMIT`: Max CPU cores (e.g., `'1.5'`).
    -   `MEMORY_LIMIT`: Max memory (e.g., `2G`, `512M`).

## Logs

-   **View Live Logs:**
    ```bash
    docker compose -f /home/kopiahhaji/siyuan-notes/compose/docker-compose.yml logs -f siyuan
    ```

-   **Export Logs to File:**
    ```bash
    docker compose -f /home/kopiahhaji/siyuan-notes/compose/docker-compose.yml logs siyuan > siyuan_logs_$(date +%Y%m%d).log
    ```

-   **Log File Location:** The container's internal logs are also mounted to the host system at:
    `/home/kopiahhaji/siyuan-notes/data/logs/`

## Maintenance

All maintenance scripts are located in the `/home/kopiahhaji/siyuan-notes/scripts/` directory.

-   **Update SiYuan:** Pulls the latest image and recreates the container after taking a pre-update backup.
    ```bash
    /home/kopiahhaji/siyuan-notes/scripts/update.sh
    ```

-   **Health Check:** Runs a series of checks to verify the service is running correctly.
    ```bash
    /home/kopiahhaji/siyuan-notes/scripts/health-check.sh
    ```

-   **Restart Service:**
    ```bash
    docker compose -f /home/kopiahhaji/siyuan-notes/compose/docker-compose.yml restart siyuan
    ```

## Troubleshooting

For common issues and solutions, please refer to the troubleshooting guide:
-   [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
