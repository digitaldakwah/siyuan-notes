#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
readonly COMPOSE_DIR="$PROJECT_DIR/compose"
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
wait_for_healthy() {
    local service_name="${COMPOSE_PROJECT_NAME:-siyuan}-app"
    log_info "Waiting for container to become healthy..."
    
    for i in {1..20}; do # Wait up to 60 seconds
        local status
        status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}no-health-check{{end}}' "$service_name" 2>/dev/null || echo "starting")
        if [[ "$status" == "healthy" ]]; then
            log_info "Container is healthy."
            return 0
        fi
        sleep 3
    done
    
    log_error "Container did not become healthy in time. Please check the container logs."
}

# --- Main Execution ---
main() {
    echo "--- SiYuan Update Process ---"
    
    # Load .env to get project name and port
    if [[ -f "$ENV_FILE" ]]; then
        set +o nounset
        # shellcheck source=/dev/null
        source "$ENV_FILE"
        set -o nounset
    fi
    
    # 1. Pre-update backup
    log_info "Creating pre-update backup..."
    local backup_name="pre-update-$(date +%Y%m%d_%H%M%S)"
    if ! "$SCRIPT_DIR/backup.sh" "$backup_name"; then
        log_error "Pre-update backup failed. Aborting update."
    fi
    log_info "Pre-update backup created successfully."
    
    # 2. Pull latest image
    log_info "Pulling latest SiYuan image..."
    if ! docker compose -f "$COMPOSE_DIR/docker-compose.yml" pull siyuan; then
        log_error "Failed to pull new image. Aborting update."
    fi
    
    # 3. Recreate container
    log_info "Recreating SiYuan container..."
    if ! docker compose -f "$COMPOSE_DIR/docker-compose.yml" up -d siyuan; then
        log_error "Failed to recreate container. Check logs for details."
    fi
    
    # 4. Verify health
    wait_for_healthy
    
    # 5. Display new version
    local port="${SIYUAN_PORT:-6806}"
    local version
    version=$(curl -s "http://localhost:$port/api/system/version" | grep -o '"version":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    log_info "Update successful. Current SiYuan Version: $version"
    
    # 6. Clean up old images
    log_info "Cleaning up dangling Docker images..."
    docker image prune -f
    
    echo "---------------------------"
    log_info "Update process finished successfully."
}

main "$@"
