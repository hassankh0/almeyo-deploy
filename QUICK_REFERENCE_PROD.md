# Almeyo Production Deployment - Quick Reference

## Daily Operations

### Start Services
```bash
docker compose -f docker-compose.prod.yml up -d
```

### Stop Services
```bash
docker compose -f docker-compose.prod.yml down
```

### View Status
```bash
docker compose -f docker-compose.prod.yml ps
```

### View Logs
```bash
# All services
docker compose -f docker-compose.prod.yml logs -f

# Backend only
docker compose -f docker-compose.prod.yml logs -f backend

# Frontend only
docker compose -f docker-compose.prod.yml logs -f frontend

# Nginx only
docker compose -f docker-compose.prod.yml logs -f nginx
```

### Restart Specific Service
```bash
# Restart backend
docker compose -f docker-compose.prod.yml restart backend

# Restart frontend
docker compose -f docker-compose.prod.yml restart frontend

# Restart nginx
docker compose -f docker-compose.prod.yml restart nginx
```

## Health Checks

### API Health
```bash
curl http://localhost/api/health
```

Expected response:
```json
{"status": "healthy", "timestamp": "2024-02-23T10:30:00Z"}
```

### Frontend Health
```bash
curl http://localhost/
```

Expected: HTTP 200 OK

### Nginx Health
```bash
curl http://localhost/health
```

Expected: HTTP 200 OK with "healthy" text

## Database Operations

### Backup Database
```bash
docker cp almeyo-backend:/app/data/almeyo.db ./backups/almeyo.db.$(date +%Y%m%d_%H%M%S)
```

### Backup Logs
```bash
docker cp almeyo-backend:/app/logs ./backups/logs_$(date +%Y%m%d_%H%M%S)
```

### Restore Database
```bash
docker cp backups/almeyo.db almeyo-backend:/app/data/almeyo.db
docker compose -f docker-compose.prod.yml restart backend
```

## Image Management

### View Docker Images
```bash
docker images | grep almeyo
```

### Rebuild Images
```bash
docker compose -f docker-compose.prod.yml build --no-cache
```

### Push to Registry (if using Docker Hub)
```bash
docker tag almeyo-backend:latest yourusername/almeyo-backend:latest
docker push yourusername/almeyo-backend:latest
```

## Volume Management

### List Volumes
```bash
docker volume ls | grep almeyo
```

### Inspect Volume
```bash
docker volume inspect almeyo_backend-data
```

### Remove Volume (WARNING: Deletes data!)
```bash
docker volume rm almeyo_backend-data
```

## Troubleshooting

### Check Container Stats
```bash
docker stats
```

### Inspect Container
```bash
docker inspect almeyo-backend
```

### Execute Command in Container
```bash
# Run shell in backend
docker exec -it almeyo-backend sh

# Run command in backend
docker exec almeyo-backend node -v
```

### View Container Details
```bash
docker ps -a
docker logs almeyo-backend
```

## Performance Monitoring

### Check Disk Usage
```bash
docker system df
```

### Check Network Connections
```bash
docker network inspect almeyo-network
```

### Memory Usage
```bash
docker stats --no-stream
```

## SSL/TLS Commands

### Check Certificate Expiration
```bash
docker run --rm -it -v /etc/letsencrypt:/etc/letsencrypt:ro \
  certbot/certbot \
  certificates
```

### Renew Certificates
```bash
docker run --rm -it \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -p 80:80 \
  certbot/certbot \
  renew --quiet
```

## Cleanup Commands

### Remove Unused Images
```bash
docker image prune -a --force
```

### Remove Unused Volumes
```bash
docker volume prune --force
```

### Clean All Docker Resources
```bash
docker compose -f docker-compose.prod.yml down -v
```

## Useful Docker Commands

### Show running containers
```bash
docker ps
```

### Show all containers
```bash
docker ps -a
```

### Remove stopped containers
```bash
docker container prune
```

### View Docker Compose config
```bash
docker compose -f docker-compose.prod.yml config
```

## Emergency Restart

If something goes wrong:

```bash
# Stop everything
docker compose -f docker-compose.prod.yml down

# Restart everything
docker compose -f docker-compose.prod.yml up -d

# Verify
docker compose -f docker-compose.prod.yml ps
```

## Useful Ports and URLs

| Service | Port | URL |
|---------|------|-----|
| Frontend | 80 | http://localhost |
| API | 80 | http://localhost/api |
| Backend (internal) | 3000 | Accessible via nginx |
| Nginx | 80, 443 | Reverse proxy |

## Volume Locations (Inside Containers)

| Volume | Path | Purpose |
|--------|------|---------|
| backend-data | /app/data | SQLite database |
| backend-logs | /app/logs | Application logs |
| backend-images | /app/public/images | Uploaded images |

## Important Files

| File | Purpose |
|------|---------|
| .env.prod | Production secrets (DO NOT COMMIT) |
| docker-compose.prod.yml | Production deployment config |
| nginx/nginx.prod.conf | Nginx production config |
| Dockerfile.prod | Backend production image |
| almeyo-frontend/Dockerfile.prod | Frontend production image |
| scripts/deploy.sh | Linux/Mac deployment script |
| scripts/deploy.ps1 | Windows deployment script |
| PRODUCTION_DEPLOYMENT.md | Full deployment guide |

## Documentation

- **Full Guide**: [PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md)
- **Backend README**: [../almeyo-backend/README.md](../almeyo-backend/README.md)
- **Backend Architecture**: [../almeyo-backend/ARCHITECTURE.md](../almeyo-backend/ARCHITECTURE.md)

## Emergency Contacts

- DevOps: [your-contact]
- Database Admin: [your-contact]
- Frontend Team: [your-contact]
