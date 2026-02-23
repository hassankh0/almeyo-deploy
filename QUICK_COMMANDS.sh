#!/bin/bash
# Quick reference for common deploy commands

# Initial Deployment (HTTP only)
./scripts/deploy-init.sh

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
