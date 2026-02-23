# Infrastructure as Code Summary - Almeyo Production

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    User Requests                     │
└────────────┬────────────────────────────────────────┘
             │ HTTP/HTTPS Port 80, 443
             │
┌────────────▼────────────────────────────────────────┐
│              nginx (Reverse Proxy)                   │
│  - SSL/TLS Termination                              │
│  - Load Balancing                                   │
│  - Caching & Compression                            │
│  - Rate Limiting & Security Headers                 │
│  Container: almeyo-nginx                            │
│  Memory: 256M limit, 128M reserved                  │
└────────────┬────────────┬────────────────────────────┘
             │            │
             │ /:80       │ /api/:3000
             │            │
    ┌────────▼──┐    ┌────▼──────────┐
    │ Frontend   │    │   Backend      │
    │ (HTML/CSS)│    │  (Node/Fastify)│
    │ Nginx     │    │ JavaScript     │
    │ Container │    │ SQLite DB      │
    │   almeyo- │    │ Container:     │
    │ frontend  │    │  almeyo-       │
    │ Memory:   │    │ backend        │
    │ 256M limit│    │ Memory: 512M   │
    │ 128M res. │    │ limit, 256M r. │
    └──────┬────┘    └────┬───────────┘
           │              │
           │              └──────────────┐
           │                     ┌───────▼────────┐
           │                     │  Docker Volumes│
           │                     │                │
           │                     │ backend-data   │
           │                     │ (SQLite DB)    │
           │                     │                │
           │                     │ backend-logs   │
           │                     │ (App Logs)     │
           │                     │                │
           │                     │ backend-images │
           │                     │ (Uploads)      │
           │                     └────────────────┘
           │
    [Docker Network: almeyo-network]
```

## Technology Stack

| Component | Technology | Version | Role |
|-----------|-----------|---------|------|
| Frontend | Nginx | 1.25-alpine | Static files + reverse proxy |
| Backend | Node.js | 20-alpine | REST API server |
| Framework | Fastify | Latest | Web framework |
| Database | SQLite | Built-in | Data storage |
| Reverse Proxy | Nginx | 1.25-alpine | SSL, routing, caching |
| Container Engine | Docker | 20.10+ | Container runtime |
| Orchestration | Docker Compose | 2.0+ | Service orchestration |

## Deployment Configuration Files

### 1. docker-compose.prod.yml
Main production orchestration file defining:
- Backend service (Node.js)
- Frontend service (Nginx)
- Reverse proxy (Nginx)
- Networks and volumes
- Health checks
- Resource limits

### 2. nginx/nginx.prod.conf
Nginx main configuration with:
- Security headers
- Rate limiting zones
- Gzip compression
- Upstream definitions
- SSL/TLS configuration (commented, ready to enable)
- Performance optimizations

### 3. Backend Dockerfile.prod
Multi-stage Docker build for Node.js:
- Stage 1: Build with npm dependencies
- Stage 2: Runtime with non-root user
- Health checks
- Resource optimization

### 4. Frontend Dockerfile.prod
Nginx-based frontend container:
- Alpine Linux base
- Security updates
- Multi-stage optimization
- Non-root execution
- Health checks

### 5. .env.prod
Production environment variables:
- Domain configuration
- SMTP settings
- API timeouts
- Logging levels
- SSL/TLS email

## Service Details

### Backend Service (Node.js/Fastify)

**Container Details:**
```yaml
Image: almeyo-backend:latest
Name: almeyo-backend
Ports: 3000 (internal, exposed to network only)
Memory: 512M limit, 256M reserved
Environment: NODE_ENV=production
Restart: unless-stopped
```

**Health Check:**
- Endpoint: `GET /api/health`
- Interval: 30s
- Timeout: 10s
- Start period: 40s
- Retries: 3

**Volumes:**
- `/app/data` → `backend-data` volume (SQLite database)
- `/app/logs` → `backend-logs` volume (Application logs)
- `/app/public/images` → `backend-images` volume (Uploaded files)

### Frontend Service (Static Files)

**Container Details:**
```yaml
Image: almeyo-frontend:latest
Name: almeyo-frontend
Ports: 80 (internal, via nginx)
Memory: 256M limit, 128M reserved
Restart: unless-stopped
```

**Health Check:**
- Endpoint: `GET /`
- Interval: 30s
- Timeout: 10s
- Start period: 30s
- Retries: 3

### Reverse Proxy (Nginx)

**Container Details:**
```yaml
Image: nginx:1.25-alpine
Name: almeyo-nginx
Ports: 80:80, 443:443
Memory: 256M limit, 128M reserved
Restart: unless-stopped
```

**Health Check:**
- Endpoint: `GET /health`
- Interval: 30s
- Timeout: 10s
- Start period: 30s
- Retries: 3

**Routing Rules:**
| Path | Destination | Cache |
|------|-------------|-------|
| `/` | Frontend | 1h HTML |
| `/api/*` | Backend:3000 | No cache |
| `/public/images/*` | Backend:3000 | 7d |
| Static files | Frontend | 30d |

## Network Architecture

### almeyo-network (Bridge Network)
- Type: Bridge driver
- Services: backend, frontend, nginx
- Internal communication only
- Nginx exposes ports 80/443 to host

## Storage Architecture

### Docker Volumes

**backend-data**
- Purpose: SQLite database storage
- Mount point: `/app/data` inside backend container
- Persistence: Survives container restart
- Backup: Must be manually backed up

**backend-logs**
- Purpose: Application logs
- Mount point: `/app/logs` inside backend container
- Retention: 30-day rolling logs
- Log rotation: Enabled in docker-compose.prod.yml

**backend-images**
- Purpose: User-uploaded images
- Mount point: `/app/public/images` inside backend container
- Served via: Nginx /public/images/ endpoint
- Cache headers: 7 days

## Security Features

### Application Level
- Running containers as non-root users
- No default passwords
- Environment variables for secrets
- Health checks for auto-recovery

### Network Level
- Isolated Docker network
- Only nginx exposes ports to host
- Internal service-to-service via DNS

### Nginx Level
- Security headers (X-Frame-Options, CSP, etc.)
- Rate limiting (API: 20r/s, Login: 5r/m)
- Connection limiting per IP
- Denial of sensitive files

### SSL/TLS Level
- Let's Encrypt support
- Automatic certificate renewal
- HTTP → HTTPS redirect
- Modern cipher suites

## Resource Management

### Memory Limits

| Service | Limit | Reservation | Purpose |
|---------|-------|-------------|---------|
| Backend | 512M | 256M | Node.js + SQLite |
| Frontend | 256M | 128M | Nginx + static files |
| Nginx Proxy | 256M | 128M | Reverse proxy + caching |
| **Total** | **1GB** | **512M** | Full stack |

### Database

**SQLite Configuration:**
- Single file: `/app/data/almeyo.db`
- Size: Typically < 100MB for restaurant data
- Backup: Manual via docker cp
- Scaling: Upgrade to PostgreSQL if > 500MB

### Logging

**Docker Logging Driver:** json-file
- Max size per log file: 10MB
- Max files to retain: 3
- Total log storage: ~30MB per service

## Deployment Procedures

### Initial Deployment
1. Prepare `.env.prod` with correct values
2. Build images: `docker compose -f docker-compose.prod.yml build`
3. Start services: `docker compose -f docker-compose.prod.yml up -d`
4. Verify health: `docker compose -f docker-compose.prod.yml ps`

### Updates
1. Stop services: `docker compose down`
2. Pull/rebuild images
3. Start services: `docker compose up -d`
4. Verify health

### Rollback
1. Keep previous backup before updates
2. Stop current: `docker compose down`
3. Restore volumes from backup
4. Start services

## Monitoring Points

### Health Checks (Automatic)
- Docker monitors health every 30s
- Failed containers auto-restart
- All services must report healthy status

### Manual Monitoring
```bash
# Check status
docker compose -f docker-compose.prod.yml ps

# View resource usage
docker stats

# Check specific service logs
docker compose logs backend
```

### Key Metrics to Monitor
- Container uptime
- Memory usage (alertif > 80% of limit)
- Disk usage for volumes
- Response times at `/api/health`
- Error rates in logs

## Backup & Recovery

### What to Backup
- Volume: `almeyo_backend-data` (SQLite database)
- Volume: `almeyo_backend-logs` (Audit trail)
- File: `.env.prod` (Secrets, encrypted)
- Directory: `almeyo-deploy/` (Configuration)

### Backup Frequency
- Database: Daily
- Logs: Weekly
- Configuration: On changes

### Recovery Time Objective (RTO)
- Service restart: < 2 minutes
- Data restore: < 5 minutes
- Full redeploy: < 10 minutes

## Scaling Considerations

### Current Limitations
- SQLite: ~500MB practical limit
- Single node: Single container per service
- No clustering/replication

### Future Scaling Steps
1. Migrate to PostgreSQL (multi-user, larger datasets)
2. Add load balancing (multiple backend instances)
3. Add caching layer (Redis)
4. Implement Kubernetes (auto-scaling, high availability)

## Cost Optimization

- **Minimal footprint**: Total memory 512M reserved
- **Single database**: SQLite, no external DB service
- **Shared infrastructure**: All services on one host
- **Efficient images**: Alpine Linux base, ~200MB total

## Next Steps for Production Readiness

- [ ] Set up SSL/TLS with Let's Encrypt
- [ ] Configure automated backups
- [ ] Set up monitoring (Prometheus + Grafana)
- [ ] Configure CI/CD pipeline (GitHub Actions)
- [ ] Document runbooks for operations team
- [ ] Test disaster recovery procedures
- [ ] Set up log aggregation (ELK, Loki)

