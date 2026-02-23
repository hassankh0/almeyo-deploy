#!/bin/bash

# Almeyo Production - Quick Commands Utility
# Usage: source QUICK_COMMANDS.sh (or run individual commands)

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Main docker-compose file
DC="docker compose -f docker-compose.prod.yml"

# ============================================
# INFORMATION & STATUS
# ============================================

# Show quick help
help() {
    echo -e "${BLUE}=== Almeyo Quick Commands ===${NC}"
    echo ""
    echo -e "${GREEN}Deployment:${NC}"
    echo "  help                   - Show this help"
    echo "  status                 - Show service status"
    echo "  health                 - Check service health"
    echo ""
    echo -e "${GREEN}LOGS:${NC}"
    echo "  logs                   - Show all logs"
    echo "  logs backend           - Show backend logs"
    echo "  logs frontend          - Show frontend logs"
    echo "  logs nginx             - Show nginx logs"
    echo ""
    echo -e "${GREEN}OPERATIONS:${NC}"
    echo "  restart [service]      - Restart service(s)"
    echo "  stop                   - Stop all services"
    echo "  backup                 - Backup database"
    echo ""
}

# ============================================
# STATUS COMMANDS
# ============================================

status() {
    echo -e "${BLUE}=== Service Status ===${NC}"
    $DC ps
}

health() {
    echo -e "${BLUE}=== Health Check ===${NC}"
    echo "Testing API..."
    curl -s -w "\nStatus: %{http_code}\n" http://localhost/api/health || echo "API unreachable"
    echo ""
    echo "Testing Frontend..."
    curl -s -w "\nStatus: %{http_code}\n" http://localhost/ || echo "Frontend unreachable"
}

# ============================================
# LOGGING
# ============================================

logs() {
    if [ -z "$1" ]; then
        echo -e "${BLUE}=== All Logs ===${NC}"
        $DC logs -f --tail=50
    else
        echo -e "${BLUE}=== $1 Logs ===${NC}"
        $DC logs -f --tail=50 "$1"
    fi
}

# ============================================
# MANAGEMENT
# ============================================

restart() {
    if [ -z "$1" ]; then
        echo -e "${BLUE}=== Restarting All Services ===${NC}"
        $DC restart
    else
        echo -e "${BLUE}=== Restarting $1 ===${NC}"
        $DC restart "$1"
    fi
    sleep 2
    status
}

stop() {
    echo -e "${BLUE}=== Stopping All Services ===${NC}"
    $DC down
}

backup() {
    BACKUP_DIR="./backups"
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    echo -e "${BLUE}=== Backing Up Database ===${NC}"
    docker cp almeyo-backend:/app/data /app/data/almeyo.db "$BACKUP_DIR/almeyo.db.$TIMESTAMP"
    echo -e "${GREEN}✓ Backed up to $BACKUP_DIR/almeyo.db.$TIMESTAMP${NC}"
}

# ============================================
# MAIN
# ============================================

if [ $# -eq 0 ]; then
    help
else
    "$@"
fi

# SSL Deployment (after DNS ready)
./scripts/deploy-ssl.sh

# Docker Compose Commands

# Check container status
docker compose -f docker-compose.prod.init.yml ps     # HTTP deployment
docker compose -f docker-compose.prod.ssl.yml ps      # HTTPS deployment

# View logs
docker compose -f docker-compose.prod.init.yml logs -f               # All services
docker compose -f docker-compose.prod.init.yml logs -f backend       # Backend only
docker compose -f docker-compose.prod.init.yml logs -f nginx         # Nginx only

# Restart services
docker compose -f docker-compose.prod.init.yml restart               # Restart all
docker compose -f docker-compose.prod.init.yml restart backend nginx # Restart specific

# Stop/Start services
docker compose -f docker-compose.prod.init.yml down                  # Stop all services
docker compose -f docker-compose.prod.init.yml up -d                 # Start all services

# Health checks
docker compose -f docker-compose.prod.init.yml ps | grep -i healthy  # Show healthy services

# View certificate info (after SSL deployment)
docker compose -f docker-compose.prod.ssl.yml exec certbot certbot certificates

# Manual certificate renewal (after SSL deployment)
docker compose -f docker-compose.prod.ssl.yml exec certbot certbot renew

# View detailed logs
docker compose -f docker-compose.prod.init.yml logs --tail=100 backend  # Last 100 lines
