# SiYuan Notes Deployment Project

## Project Overview
Deploying SiYuan Notes (privacy-first personal knowledge management system) on Docker VM in Proxmox environment.

## Environment Details
- Platform: Digital Dakwah Notes
- Location: Papar, Sabah, Malaysia
- Timezone: Asia/Kuala_Lumpur (GMT+8)
- Target directory: /home/kopiahhaji/siyuan-notes

## Deployment Goals
1. Set up SiYuan with Docker Compose
2. Configure automated backups
3. Implement monitoring and health checks
4. Document everything in Git repository
5. Integrate with existing Cloudflare Tunnel infrastructure

## Requirements
- Docker and Docker Compose installed
- Port 6806 available
- Minimum 2GB RAM, 10GB disk space
- Git for version control

## Safety Rules
- Always show commands before executing destructive operations
- Request confirmation before stopping containers
- Create backups before major changes
- Validate configurations before deployment

## Preferences
- Use bash scripts with strict error handling (set -euo pipefail)
- Color-coded output for logs (green=success, yellow=warning, red=error)
- Follow Infrastructure as Code principles
- Professional documentation with markdown

Show me the created file after completion.
