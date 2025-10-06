# Troubleshooting Guide

This guide provides solutions to common problems you might encounter while running the SiYuan Notes service.

## Common Issues

---

### Container Won't Start

-   **Problem:** The `siyuan-app` container fails to start, exits immediately, or is stuck in a restart loop.

-   **Solutions:**
    1.  **Check Logs:** The first step is always to check the container's logs for specific error messages.
        ```bash
        cd /home/kopiahhaji/siyuan-notes/compose && docker compose logs siyuan
        ```
    2.  **Verify `.env` File:** Look for syntax errors, special characters, or missing values in your `compose/.env` file.
        ```bash
        cat /home/kopiahhaji/siyuan-notes/compose/.env
        ```
    3.  **Check for Port Conflicts:** Another process on the host might be using the port required by SiYuan.
        ```bash
        ss -tulpn | grep 6806
        ```
    4.  **Fix:** If the port is in use, change `SIYUAN_PORT` in your `.env` file to an available port and recreate the container.

---

### Permission Issues

-   **Problem:** The container logs show "Permission denied" errors when trying to read or write to the data directories.

-   **Solutions:**
    1.  **Fix Data Permissions:** Ensure the user running the Docker container owns the `data` directory.
        ```bash
        sudo chown -R $USER:$USER /home/kopiahhaji/siyuan-notes/data
        ```
    2.  **Check PUID/PGID:** Get the correct User ID (PUID) and Group ID (PGID) for your current user.
        ```bash
        id $USER
        ```
    3.  **Update `.env`:** Make sure the `PUID` and `PGID` values in your `compose/.env` file match the output from the `id` command.
    4.  **Restart:** Apply the changes by restarting the container.
        ```bash
        docker compose -f /home/kopiahhaji/siyuan-notes/compose/docker-compose.yml restart siyuan
        ```

---

### Cannot Access Web Interface

-   **Problem:** The SiYuan UI is unreachable at `http://<docker-vm-ip>:6806`.

-   **Solutions:**
    1.  **Check Container Status:** Ensure the container is running and healthy.
        ```bash
        docker compose -f /home/kopiahhaji/siyuan-notes/compose/docker-compose.yml ps
        ```
    2.  **Test Locally on Host:** Use `curl` on the Docker host to see if the service is responding locally.
        ```bash
        curl http://localhost:6806
        ```
    3.  **Check Firewall:** The firewall on your Docker VM might be blocking the port.
        ```bash
        sudo ufw status
        ```
    4.  **Allow Port:** If the firewall is active, create a rule to allow traffic on the SiYuan port.
        ```bash
        sudo ufw allow 6806/tcp
        ```

---

### WebSocket Connection Issues

-   **Problem:** Real-time synchronization and updates are not working in the web interface.

-   **Solutions:**
    1.  **Check Browser Console:** Open your browser's developer tools (F12) and check the Console tab for WebSocket connection errors.
    2.  **Verify Nginx Config:** If using a reverse proxy, ensure your Nginx configuration correctly proxies WebSocket traffic (`/ws`) and includes the necessary headers (`Upgrade`, `Connection`).
    3.  **Check Proxy Timeouts:** WebSocket connections are long-lived. Ensure your proxy's timeout settings are high enough (e.g., `7d`).

---

### High Memory Usage

-   **Problem:** The `siyuan-app` container is consuming an unexpectedly high amount of memory.

-   **Solutions:**
    1.  **Check Current Usage:** Get a live view of resource consumption.
        ```bash
        docker stats siyuan-app
        ```
    2.  **Review Workspace Size:** A very large workspace can lead to higher memory usage.
        ```bash
        du -sh /home/kopiahhaji/siyuan-notes/data/workspace
        ```
    3.  **Adjust Memory Limit:** If necessary, increase the memory limit in `compose/.env`.
        ```
        MEMORY_LIMIT=4G
        ```
    4.  **Restart:** Recreate the container to apply the new limit.
        ```bash
        cd /home/kopiahhaji/siyuan-notes/compose && docker compose down && docker compose up -d
        ```

---

### Backup Failures

-   **Problem:** The `backup.sh` script fails or creates incomplete/corrupted archives.

-   **Solutions:**
    1.  **Check Disk Space:** Ensure you have enough free disk space to create the backup archive.
        ```bash
        df -h /home/kopiahhaji/siyuan-notes
        ```
    2.  **Verify Permissions:** The script needs write permissions in the `backups/` directory.
        ```bash
        ls -la /home/kopiahhaji/siyuan-notes/
        ```
    3.  **Run a Manual Test:** Execute the script with a test name to see live output.
        ```bash
        /home/kopiahhaji/siyuan-notes/scripts/backup.sh test-backup
        ```

## Diagnostic Commands

-   **Full Health Check:** `./scripts/health-check.sh`
-   **View Last 100 Log Lines:** `docker compose -f /home/kopiahhaji/siyuan-notes/compose/docker-compose.yml logs --tail=100 siyuan`
-   **Inspect Container Details:** `docker inspect siyuan-app`
-   **Check Network Configuration:** `docker network inspect siyuan_net`
-   **One-time Resource Usage:** `docker stats --no-stream siyuan-app`

## Getting Help

1.  **Run Health Check:** Always start by running the health check script to get a baseline.
2.  **Review Logs:** Carefully examine the container logs for error messages.
3.  **Check GitHub Issues:** See if others have reported a similar issue on the official SiYuan GitHub repository.
4.  **Document Errors:** Copy and paste the exact error messages when seeking help.
5.  **Review Recent Changes:** Think about any configuration changes you made recently.

## Debug Mode

To see verbose, real-time logs directly from the container, you can run it in the foreground.

1.  **Stop the detached container:**
    ```bash
    cd /home/kopiahhaji/siyuan-notes/compose && docker compose down
    ```
2.  **Start in foreground:**
    ```bash
    docker compose up siyuan
    ```
3.  **Monitor the logs.** When you are finished, press `Ctrl+C` to stop the container.
4.  **Return to detached mode:**
    ```bash
    docker compose up -d
    ```
