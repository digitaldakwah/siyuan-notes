#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
readonly COMPOSE_DIR="$PROJECT_DIR/compose"
readonly DATA_DIR="$PROJECT_DIR/data"
readonly BACKUP_DIR="$PROJECT_DIR/backups"
readonly WORKSPACE_DIR="$DATA_DIR/workspace"
readonly CONFIG_DIR="$DATA_DIR/config"
readonly ENV_FILE="$COMPOSE_DIR/.env"

# --- Colors ---
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# --- Logging ---
log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

# --- Main Functions ---
usage() {
    echo "Usage: $0 <path_to_backup_file.tar.gz>"
    echo
    echo "Available backups in $BACKUP_DIR:"
    ls -1 "$BACKUP_DIR"/*.tar.gz | sed 's/^/  /'
    exit 1
}

load_env() {
    if [[ -f "$ENV_FILE" ]]; then
        set +o nounset
        # shellcheck source=/dev/null
        source "$ENV_FILE"
        set -o nounset
    else
        log_warn "Environment file not found at $ENV_FILE. Using defaults."
    fi
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
        # Suppress errors in case the container is not yet running
        local status
        status=$(docker inspect --format '{{.State.Health.Status}}' "$service_name" 2>/dev/null || echo "starting")
        if [[ "$status" == "healthy" ]]; then
            log_info "SiYuan container is healthy."
            return 0
        fi
        sleep 3
    done
    
    log_error "SiYuan container did not become healthy in time."
}

rollback() {
    log_warn "An error occurred. Attempting to roll back..."
    if [[ -d "$SAFETY_BACKUP_DIR" ]]; then
        log_info "Restoring safety backup from $SAFETY_BACKUP_DIR"
        rm -rf "$WORKSPACE_DIR" "$CONFIG_DIR"
        mv "$SAFETY_BACKUP_DIR/workspace" "$WORKSPACE_DIR"
        mv "$SAFETY_BACKUP_DIR/config" "$CONFIG_DIR"
        log_info "Rollback complete."
    else
        log_error "Safety backup directory not found. Cannot roll back."
    fi
    manage_container "start"
}

# --- Main Execution ---
main() {
    local backup_file="${1-}"
    
    if [[ -z "$backup_file" ]]; then
        usage
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
    fi
    
    local checksum_file="$backup_file.sha256"
    if [[ -f "$checksum_file" ]]; then
        log_info "Verifying checksum..."
        if ! sha256sum -c "$checksum_file"; then
            log_error "Checksum validation failed."
        fi
        log_info "Checksum OK."
    else
        log_warn "Checksum file not found ($checksum_file). Cannot verify integrity."
    fi
    
    log_warn "This will completely overwrite the current SiYuan data."
    log_warn "A safety backup of the current data will be created."
    echo -n "Type 'yes' to continue: "
    read -r confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        log_error "Restore operation cancelled."
    fi
    
    load_env
    
    trap 'rollback' ERR
    
    manage_container "stop"
    
    # Create safety backup
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    SAFETY_BACKUP_DIR="$BACKUP_DIR/safety-backup-$timestamp"
    
    log_info "Creating safety backup of current data to $SAFETY_BACKUP_DIR"
    mkdir -p "$SAFETY_BACKUP_DIR"
    # Use mv for speed, handle case where directories might not exist
    mv "$WORKSPACE_DIR" "$SAFETY_BACKUP_DIR/workspace" 2>/dev/null || true
    mv "$CONFIG_DIR" "$SAFETY_BACKUP_DIR/config" 2>/dev/null || true
    
    log_info "Clearing current data directories..."
    mkdir -p "$WORKSPACE_DIR" "$CONFIG_DIR"
    
    log_info "Extracting backup archive..."
    if ! tar -xzf "$backup_file" -C "$DATA_DIR"; then
        log_error "Failed to extract backup archive."
    fi
    
    log_info "Fixing permissions..."
    if ! chown -R "$USER:$USER" "$DATA_DIR"; then
        log_error "Failed to set permissions. Try running with sudo."
    fi
    
    # Clear trap on success before starting container
    trap - ERR
    
    manage_container "start"
    
    wait_for_healthy
    
    log_info "Restore complete."
    log_info "A safety backup of your previous data is located at:"
    log_info "$SAFETY_BACKUP_DIR"
}

main "$@"
