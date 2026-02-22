#!/bin/bash
# Quick reference for common deploy commands

# Initial Deployment (HTTP only)
./scripts/deploy-init.sh

# SSL Deployment (after DNS ready)
./scripts/deploy-ssl.sh

# Daily Management
./scripts/manage-prod.sh status           # Show container status
./scripts/manage-prod.sh logs             # View all logs
./scripts/manage-prod.sh logs backend 50  # View backend logs (last 50 lines)
./scripts/manage-prod.sh health-check     # Test all services
./scripts/manage-prod.sh restart          # Restart all services
./scripts/manage-prod.sh restart nginx    # Restart nginx only

# Certificate Management
./scripts/manage-prod.sh cert-info        # Show certificate expiry
./scripts/manage-prod.sh cert-renew       # Manually renew certificate

# Backup & Restore
./scripts/manage-prod.sh backup           # Create backup
./scripts/manage-prod.sh restore backups/almeyo_backup_YYYYMMDD_HHMMSS.tar.gz

# Updates
./scripts/manage-prod.sh update           # Update code and rebuild

# Manual Docker Compose Commands
# Test HTTP deployment
docker-compose -f docker-compose.prod.init.yml ps
docker-compose -f docker-compose.prod.init.yml logs -f

# Test HTTPS deployment
docker-compose -f docker-compose.prod.ssl.yml ps
docker-compose -f docker-compose.prod.ssl.yml logs -f nginx

# Stop all services
./scripts/manage-prod.sh stop
# or
docker-compose -f docker-compose.prod.ssl.yml down
