# SiYuan Notes Deployment Progress

This checklist tracks the progress of deploying the SiYuan Notes service.

## Phase 1: Initial Setup & Configuration
- [ ] Initialize Git repository
- [ ] Define project structure and create initial directories (`compose`, `data`, `scripts`, etc.)
- [ ] Create `.gitignore` file to exclude sensitive data and local artifacts
- [ ] Create `GEMINI.md` to define project goals and context
- [ ] Create `compose/.env.example` with all required environment variables
- [ ] Copy `.env.example` to `.env` and populate with production values

## Phase 2: Docker Compose & Service Definition
- [ ] Create `compose/docker-compose.yml`
- [ ] Define the `siyuan` service with appropriate image, volumes, and ports
- [ ] Implement resource limits (CPU, memory) for the `siyuan` service
- [ ] Add a health check for the `siyuan` service
- [ ] Define the `nginx` reverse proxy service (optional, with `proxy` profile)
- [ ] Configure the custom bridge network (`siyuan_net`)
- [ ] Validate the Docker Compose file syntax (`docker compose config`)
- [ ] Launch the stack and verify `siyuan` container starts successfully

## Phase 3: Backup & Recovery
- [ ] Create the backup script `scripts/backup.sh`
- [ ] Implement strict error handling (`set -euo pipefail`)
- [ ] Add color-coded logging for info, warnings, and errors
- [ ] Implement logic to stop, back up (workspace + config), and restart the container
- [ ] Add health check verification after restarting the container
- [ ] Implement automated cleanup of old backups
- [ ] Make the backup script executable (`chmod +x`)
- [ ] Perform a test backup and restore to validate the process

## Phase 4: Security & Networking
- [ ] Configure Nginx for SSL termination (HTTPS)
- [ ] Set up Cloudflare Tunnel to expose the service securely
- [ ] Restrict direct access to port 6806 on the host firewall
- [ ] Ensure file permissions on the host are secure
- [ ] Verify that no secrets or sensitive data are committed to the Git repository

## Phase 5: Automation & Monitoring
- [ ] Set up a cron job to run the backup script on a schedule (e.g., daily)
- [ ] Implement a basic health check monitoring script (`scripts/healthcheck.sh`)
- [ ] (Optional) Integrate with a monitoring service like Uptime Kuma or Prometheus

## Phase 6: Documentation
- [ ] Create `README.md` with detailed setup and usage instructions
- [ ] Document the backup and restore procedure
- [ ] Document the environment variables required for configuration

## Phase 7: Production Deployment & Go-Live
- [ ] Run a final end-to-end test of the entire setup
- [ ] Push the complete Git repository to a remote server (e.g., GitHub, Gitea)
- [ ] Deploy the application on the production Proxmox VM
- [ ] Announce the service is live
