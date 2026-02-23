# PRODUCTION DEPLOYMENT GUIDE - Almeyo

## Overview

This guide explains how to deploy Almeyo in production using Docker Compose, following best practices from the Olivié project. The setup includes:

- **Frontend**: Static HTML files served by Nginx
- **Backend**: Node.js application with Fastify
- **Reverse Proxy**: Nginx for routing and SSL termination
- **Data Persistence**: Docker volumes for database and logs
- **Health Checks**: Automatic health monitoring for all services
- **Resource Limits**: Memory and CPU limits for containers
- **Logging**: Centralized logging with size limits

## Prerequisites

1. Docker Engine 20.10+ installed
2. Docker Compose 2.0+ installed
3. At least 2GB free disk space
4. Ports 80 and 443 available on the host machine

## Setup Steps

### 1. Prepare Environment Configuration

Create production environment file from template:

```bash
cp .env.prod.example .env.prod
```

Edit `.env.prod` and fill in required values:

```env
DOMAIN=your-domain.com
CERT_EMAIL=your-email@example.com
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

**Important**: Keep `.env.prod` secure and never commit it to git.

### 2. Build Docker Images

Build optimized production images:

```bash
docker compose -f docker-compose.prod.yml build --no-cache
```

This builds three images:
- `almeyo-backend:latest` - Node.js backend with production optimizations
- `almeyo-frontend:latest` - Static site with Nginx
- `nginx:1.25-alpine` - Reverse proxy

### 3. Start Services

Start all services in detached mode:

```bash
docker compose -f docker-compose.prod.yml up -d
```

### 4. Verify Deployment

Check service status:

```bash
docker compose -f docker-compose.prod.yml ps
```

Expected output:
```
NAME                    STATUS
almeyo-backend         Up (healthy)
almeyo-frontend        Up (healthy)
almeyo-nginx          Up (healthy)
```

Test endpoints:

```bash
# Health check
curl http://localhost/health

# Frontend
curl http://localhost/

# API
curl http://localhost/api/health
```

### 5. View Logs

Check service logs:

```bash
# All services
docker compose -f docker-compose.prod.yml logs -f

# Specific service
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend
docker compose -f docker-compose.prod.yml logs -f nginx
```

## Using Deployment Scripts

### Linux/Mac

Make script executable:

```bash
chmod +x scripts/deploy.sh
```

Run deployment:

```bash
# Full deployment
./scripts/deploy.sh deploy

# View logs
./scripts/deploy.sh logs

# Stop services
./scripts/deploy.sh stop

# Restart services
./scripts/deploy.sh restart

# Verify deployment
./scripts/deploy.sh verify
```

### Windows PowerShell

Run deployment script:

```powershell
.\scripts\deploy.ps1
```

## Container Resource Limits

Production configuration includes memory limits:

| Service | Limit | Reservation |
|---------|-------|------------|
| Backend | 512M | 256M |
| Frontend | 256M | 128M |
| Nginx | 256M | 128M |
| **Total** | **1GB** | **512M** |

Adjust based on your server capacity.

## Health Checks

Each service monitors its own health:

- **Backend**: HTTP GET `/api/health` (30s interval, 40s delay)
- **Frontend**: HTTP GET `/` (30s interval, 30s delay)
- **Nginx**: HTTP GET `/health` (30s interval, 30s delay)

Docker automatically restarts unhealthy services.

## SSL/TLS Configuration (HTTPS)

### Using Let's Encrypt with Certbot

1. Uncomment the HTTPS server block in `nginx/nginx.prod.conf`

2. Run Certbot (initially without renewal):

```bash
docker run --rm -it \
  -v "/etc/letsencrypt:/etc/letsencrypt" \
  -v "/var/log/letsencrypt:/var/log/letsencrypt" \
  -p 80:80 \
  certbot/certbot \
  certonly --standalone \
  -d your-domain.com \
  -d www.your-domain.com \
  --email your-email@example.com \
  --agree-tos
```

3. Once certificates are obtained, restart Nginx:

```bash
docker compose -f docker-compose.prod.yml restart nginx
```

4. Set up automatic renewal with cron (Linux):

```bash
# Add to crontab
0 0 * * * docker run --rm -it \
  -v "/etc/letsencrypt:/etc/letsencrypt" \
  -v "/var/log/letsencrypt:/var/log/letsencrypt" \
  -p 80:80 \
  certbot/certbot \
  renew --quiet && \
  docker compose -f /path/to/docker-compose.prod.yml restart nginx
```

## Data Persistence

### Volumes

All persistent data is stored in Docker volumes:

- `backend-data` - SQLite database and seed data
- `backend-logs` - Application logs
- `backend-images` - Uploaded images

Inspect volumes:

```bash
docker volume ls | grep almeyo
```

Backup volume data:

```bash
docker cp almeyo-backend:/app/data ./backup/
docker cp almeyo-backend:/app/logs ./backup/
```

## Performance Tuning

### Nginx Configuration

The `nginx.prod.conf` includes:

- **Gzip Compression**: Reduces transfer size (1000+ bytes)
- **Caching Headers**: Browser and CDN caching
- **Rate Limiting**: Protection against abuse
- **Connection Pooling**: Efficient backend connections

### Backend Optimization

- Node.js runs with `--max-old-space-size=256`
- Production dependencies only (no dev packages)
- Multi-stage Docker build for minimal image size

### Frontend Optimization

- Static files cached for 30 days
- HTML files cached for 1 hour
- API responses not cached
- Gzip compression enabled

## Monitoring & Maintenance

### Check Service Status

```bash
docker compose -f docker-compose.prod.yml ps
```

### View Resource Usage

```bash
docker stats
```

### Clean Up Unused Resources

```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune
```

### Update Services

1. Pull latest images (if using pre-built)
2. Rebuild with `docker compose build`
3. Restart with `docker compose up -d`

## Troubleshooting

### Services not starting

Check logs:

```bash
docker compose -f docker-compose.prod.yml logs
```

### High memory usage

Check container stats:

```bash
docker stats
```

Increase memory limits in `docker-compose.prod.yml`:

```yaml
deploy:
  resources:
    limits:
      memory: 1024M
```

### Port conflicts

If port 80/443 already in use:

```bash
# Find what's using port 80
lsof -i :80  # Linux/Mac
netstat -ano | findstr :80  # Windows

# Or change Nginx port in docker-compose.prod.yml
ports:
  - "8080:80"
  - "8443:443"
```

### Database issues

Reset database (will lose data):

```bash
docker volume rm almeyo_backend-data
docker compose -f docker-compose.prod.yml up -d backend
```

## Rollback Procedure

If deployment fails and you need to rollback:

```bash
# Stop current deployment
docker compose -f docker-compose.prod.yml down

# Restore from backup (created before deployment)
docker cp backups/data_TIMESTAMP almeyo-backend:/app/
docker cp backups/logs_TIMESTAMP almeyo-backend:/app/

# Bring services back up
docker compose -f docker-compose.prod.yml up -d
```

## Security Considerations

1. **Environment Variables**: Never commit `.env.prod` to git
2. **SSL/TLS**: Use HTTPS in production
3. **File Permissions**: Containers run as non-root users
4. **Rate Limiting**: Nginx rate limits protect against abuse
5. **Health Checks**: Automatic restart of failed services
6. **Logging**: All requests logged for audit trails

## Variables and Configuration

### Environment Variables

See `.env.prod` for all configurable options.

### Docker Compose Files

- `docker-compose.yaml` - Development setup
- `docker-compose.prod.yml` - Production setup

### Nginx Configuration

- `nginx/nginx.conf` - Base configuration (development)
- `nginx/nginx.prod.conf` - Production optimized
- `nginx/conf.d.prod/` - Additional configs

## Next Steps

1. Test thoroughly in staging environment first
2. Set up automated backups
3. Configure monitoring and alerts
4. Document your deployment process
5. Create runbooks for common operations

## Support

For issues or questions, check the application documentation in:
- [README](../almeyo-backend/README.md)
- [Architecture](../almeyo-backend/ARCHITECTURE.md)

