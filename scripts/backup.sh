#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
readonly COMPOSE_DIR="$PROJECT_DIR/compose"
readonly BACKUP_DIR="$PROJECT_DIR/backups"
readonly WORKSPACE_DIR="$PROJECT_DIR/data/workspace"
readonly CONFIG_DIR="$PROJECT_DIR/data/config"
readonly ENV_FILE="$COMPOSE_DIR/.env"

# --- Colors ---
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# --- Logging ---
log_info() {
    local message="[INFO] $1"
    echo -e "${GREEN}${message}${NC}"
    logger -t siyuan-backup -p user.info "$message"
}

log_warn() {
    local message="[WARN] $1"
    echo -e "${YELLOW}${message}${NC}" >&2
    logger -t siyuan-backup -p user.warning "$message"
}

log_error() {
    local message="[ERROR] $1"
    echo -e "${RED}${message}${NC}" >&2
    logger -t siyuan-backup -p user.err "$message"
    exit 1
}

# --- Main Functions ---
load_env() {
    if [[ -f "$ENV_FILE" ]]; then
        log_info "Loading environment variables from $ENV_FILE"
        # Temporarily disable unbound variable check for source
        set +o nounset
        # shellcheck source=/dev/null
        source "$ENV_FILE"
        set -o nounset
    else
        log_warn "Environment file not found at $ENV_FILE. Using defaults."
    fi
}

verify_workspace() {
    if [[ ! -d "$WORKSPACE_DIR" ]]; then
        log_error "Workspace directory not found at $WORKSPACE_DIR"
    fi
    log_info "Workspace directory found at $WORKSPACE_DIR"
}

manage_container() {
    local action="$1"
    local service_name="${COMPOSE_PROJECT_NAME:-siyuan}-app"
    
    log_info "${action^}ing SiYuan container ($service_name)..."
    if ! docker compose -f "$COMPOSE_DIR/docker-compose.yml" "$action" "$service_name"; then
        log_error "Failed to $action SiYuan container."
    fi
}

wait_for_healthy() {
    local service_name="${COMPOSE_PROJECT_NAME:-siyuan}-app"
    log_info "Waiting for SiYuan container to be healthy..."
    
    for i in {1..20}; do
        local status
        status=$(docker inspect --format '{{.State.Health.Status}}' "$service_name" 2>/dev/null)
        if [[ "$status" == "healthy" ]]; then
            log_info "SiYuan container is healthy."
            return 0
        fi
        sleep 3
    done
    
    log_error "SiYuan container did not become healthy in time."
}

create_backup() {
    local backup_name="$1"
    local backup_file="$BACKUP_DIR/$backup_name.tar.gz"
    
    log_info "Creating backup archive: $backup_file"
    
    if ! tar -czf "$backup_file" -C "$PROJECT_DIR/data" workspace config; then
        log_error "Failed to create backup archive."
    fi
    
    log_info "Generating SHA256 checksum..."
    sha256sum "$backup_file" > "$backup_file.sha256"
    
    log_info "Backup complete."
    log_info "Backup file size: $(du -h "$backup_file" | cut -f1)"
}

cleanup_old_backups() {
    local retention_days="${BACKUP_RETENTION_DAYS:-30}"
    log_info "Cleaning up backups older than $retention_days days..."
    
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime "+$retention_days" -print -delete | while read -r f; do
        log_info "Deleted old backup: $f"
        rm -f "$f.sha256"
    done
}

# --- Main Execution ---
main() {
    trap 'log_error "An unexpected error occurred. Aborting."; exit 1' ERR
    
    load_env
    
    local backup_name="${1:-siyuan-backup-$(date +%Y%m%d_%H%M%S)}"
    
    log_info "Starting SiYuan backup process..."
    
    verify_workspace
    
    manage_container "stop"
    
    create_backup "$backup_name"
    
    manage_container "start"
    
    wait_for_healthy
    
    cleanup_old_backups
    
    log_info "Backup process finished successfully."
}

main "$@"
