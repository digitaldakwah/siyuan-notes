#!/usr/bin/env bash
# Loosely handle errors to allow all checks to run
set -uo pipefail

# --- Configuration ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
readonly COMPOSE_DIR="$PROJECT_DIR/compose"
readonly BACKUP_DIR="$PROJECT_DIR/backups"
readonly ENV_FILE="$COMPOSE_DIR/.env"

# --- Colors and Symbols ---
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color
readonly TICK="✓"
readonly CROSS="✗"
readonly WARN="!"

# --- State ---
exit_code=0
overall_status="HEALTHY"

# --- Helper Functions ---
print_check() {
    local status_color="$1"
    local status_symbol="$2"
    local message="$3"
    echo -e "${status_color}[${status_symbol}]${NC} ${message}"
}

set_status() {
    local level="$1"
    if [[ "$level" == "UNHEALTHY" ]]; then
        exit_code=1
        overall_status="UNHEALTHY"
    elif [[ "$level" == "WARNING" && "$overall_status" != "UNHEALTHY" ]]; then
        overall_status="WARNING"
    fi
}

# --- Main Execution ---
main() {
    echo "--- SiYuan Health Check ---"
    
    # Load .env to get project name and port
    if [[ -f "$ENV_FILE" ]]; then
        set +o nounset
        # shellcheck source=/dev/null
        source "$ENV_FILE"
        set -o nounset
    fi
    local service_name="siyuan-app"
    local port="${SIYUAN_PORT:-6806}"

    # 1. Container Running Status
    local container_state
    container_state=$(docker compose -f "$COMPOSE_DIR/docker-compose.yml" ps -q "$service_name" | xargs docker inspect -f '{{.State.Status}}' 2>/dev/null || echo "not-found")
    if [[ "$container_state" == "running" ]]; then
        print_check "$GREEN" "$TICK" "Container '$service_name' is running."
    else
        print_check "$RED" "$CROSS" "Container '$service_name' is not running (State: $container_state)."
        set_status "UNHEALTHY"
    fi

    # 2. Docker Health Check Status
    if [[ "$container_state" == "running" ]]; then
        local health_status
        health_status=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}no-health-check{{end}}' "$service_name")
        case "$health_status" in
            healthy)
                print_check "$GREEN" "$TICK" "Docker health status is healthy."
                ;;
            unhealthy)
                print_check "$RED" "$CROSS" "Docker health status is unhealthy."
                set_status "UNHEALTHY"
                ;;
            starting)
                print_check "$YELLOW" "$WARN" "Docker health status is starting."
                set_status "WARNING"
                ;;
            *)
                print_check "$YELLOW" "$WARN" "Container does not have a health check configured."
                set_status "WARNING"
                ;;
        esac
    else
        print_check "$RED" "$CROSS" "Skipping Docker health check (container not running)."
    fi

    # 3. API Endpoint
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/api/system/version" || echo "000")
    if [[ "$http_code" -eq 200 ]]; then
        local version
        version=$(curl -s "http://localhost:$port/api/system/version" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
        print_check "$GREEN" "$TICK" "API endpoint is responsive. SiYuan Version: $version"
    else
        print_check "$RED" "$CROSS" "API endpoint is not responsive (HTTP Code: $http_code)."
        set_status "UNHEALTHY"
    fi

    # 4. Disk Space Usage
    local disk_usage
    disk_usage=$(df -h "$PROJECT_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ "$disk_usage" -gt 80 ]]; then
        print_check "$YELLOW" "$WARN" "Disk usage is high: ${disk_usage}%"
        set_status "WARNING"
    else
        print_check "$GREEN" "$TICK" "Disk usage is normal: ${disk_usage}%"
    fi

    # 5. Container Memory Usage
    if [[ "$container_state" == "running" ]]; then
        local mem_usage
        mem_usage=$(docker stats --no-stream --format "{{.MemUsage}}" "$service_name")
        print_check "$GREEN" "$TICK" "Container memory usage: $mem_usage"
    else
        print_check "$RED" "$CROSS" "Skipping memory usage check (container not running)."
    fi

    # 6. Last Backup Age
    local last_backup_file
    last_backup_file=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -print0 | xargs -0 ls -t | head -n 1)
    if [[ -n "$last_backup_file" ]]; then
        local last_backup_ts
        last_backup_ts=$(stat -c %Y "$last_backup_file")
        local now_ts
        now_ts=$(date +%s)
        local age_seconds=$((now_ts - last_backup_ts))
        local age_days=$((age_seconds / 86400))
        
        if [[ "$age_days" -gt 7 ]]; then
            print_check "$YELLOW" "$WARN" "Last backup is ${age_days} days old."
            set_status "WARNING"
        else
            print_check "$GREEN" "$TICK" "Last backup is ${age_days} days old."
        fi
    else
        print_check "$YELLOW" "$WARN" "No backups found in $BACKUP_DIR."
        set_status "WARNING"
    fi

    # --- Summary ---
    echo "---------------------------"
    case "$overall_status" in
        HEALTHY)
            echo -e "Overall Status: ${GREEN}HEALTHY${NC}"
            ;;
        WARNING)
            echo -e "Overall Status: ${YELLOW}WARNING${NC}"
            ;;
        UNHEALTHY)
            echo -e "Overall Status: ${RED}UNHEALTHY${NC}"
            ;;
    esac
    
    exit $exit_code
}

main
