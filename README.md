# Almeyo Deploy Repository

Production deployment infrastructure for Almeyo Restaurant website.

## Repository Structure

```
almeyo-deploy/
├── docker-compose.prod.init.yml      # Step 1: HTTP-only deployment (ACME validation)
├── docker-compose.prod.ssl.yml       # Step 2: Full SSL/TLS deployment
├── .env.prod.example                 # Environment variables template
├── nginx/
│   ├── nginx.conf                    # Production Nginx config
│   ├── nginx.conf.init               # HTTP-only Nginx config
│   ├── conf.d/
│   │   └── almeyo.conf              # SSL/TLS server config
│   ├── conf.d.init/
│   │   └── almeyo.conf              # HTTP-only server config
│   └── certbot-webroot/              # Let's Encrypt ACME challenges
├── scripts/
│   ├── deploy-init.sh                # Initial deployment (HTTP)
│   ├── deploy-ssl.sh                 # SSL deployment
│   ├── manage-prod.sh                # Production management utility
│   └── renew-cert.sh                 # Certificate renewal script
└── docs/
    ├── DEPLOYMENT_GUIDE.md           # Step-by-step deployment
    ├── TROUBLESHOOTING.md            # Common issues and fixes
    └── README.md                     # This file
```

## Quick Start

### Prerequisites
- **Docker** and **Docker Compose** installed
- **Git** for pulling code
- **Domain** configured with DNS A record pointing to server IP
- **Email** for Let's Encrypt notifications (CERT_EMAIL in .env)

### Step 1: HTTP Deployment (ACME Validation)

```bash
# Clone the repository
git clone <your-repo> almeyo-deploy
cd almeyo-deploy

# Copy and configure environment
cp .env.prod.example .env
# Edit .env and enter: DOMAIN, CERT_EMAIL, SMTP credentials

# Make scripts executable
chmod +x scripts/*.sh

# Run initial deployment
./scripts/deploy-init.sh
```

**Verify:** Visit `http://your-domain.com` in your browser

### Step 2: SSL Deployment (After DNS Propagation)

After DNS is fully propagated (24-48 hours):

```bash
# Deploy SSL/TLS with Let's Encrypt
./scripts/deploy-ssl.sh
```

**Verify:** Visit `https://your-domain.com` in your browser

### Step 3: Daily Operations

```bash
# View logs
./scripts/manage-prod.sh logs

# Check service health
./scripts/manage-prod.sh health-check

# Restart services
./scripts/manage-prod.sh restart

# Check certificate expiry
./scripts/manage-prod.sh cert-info

# Backup database
./scripts/manage-prod.sh backup
```

## Two-Step Deployment Pattern

Almeyo uses a two-step deployment process required for Let's Encrypt:

**Step 1: HTTP Only**
- Nginx runs on port 80 (HTTP)
- No Certbot running
- ACME challenge endpoint available at `/.well-known/acme-challenge/`
- Purpose: Allow Let's Encrypt to validate domain ownership

**Step 2: SSL/TLS**
- Nginx runs on ports 80 and 443 (HTTP + HTTPS)
- Certbot service obtains and renews certificates
- HTTP traffic redirected to HTTPS
- OCSP stapling enabled
- Auto-renewal configured

## Configuration

### Environment Variables (.env)

```bash
DOMAIN=almeyo.com
CERT_EMAIL=admin@almeyo.com
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
NODE_ENV=production
```

**Notes:**
- For Gmail: Generate app password at https://myaccount.google.com/apppasswords
- DOMAIN must match SSL certificate domain
- CERT_EMAIL receives Let's Encrypt expiry notifications

## Security Features

✅ **TLS 1.2 & 1.3** - Modern encryption standards
✅ **Strong Ciphers** - ECDHE and DHE key exchange
✅ **HSTS** - HTTP Strict Transport Security (1 year)
✅ **CSP** - Content Security Policy headers
✅ **OCSP Stapling** - Faster certificate validation
✅ **Security Headers** - X-Frame-Options, X-Content-Type-Options, etc.
✅ **Rate Limiting** - 10 req/s general, 30 req/s API
✅ **gzip Compression** - Faster asset delivery

## Monitoring

### Health Checks

Services have built-in health checks:
- Backend: HTTP GET /api/health
- Frontend: HTTP GET /
- Nginx: HTTP GET / (SSL/TLS)
- Certbot: Service completion check

```bash
./scripts/manage-prod.sh health-check
```

### Logs

```bash
# All services
./scripts/manage-prod.sh logs

# Specific service
./scripts/manage-prod.sh logs nginx

# Last 100 lines
./scripts/manage-prod.sh logs backend 100

# Follow logs (real-time)
docker-compose -f docker-compose.prod.ssl.yml logs -f
```

### Certificate Monitoring

```bash
# View certificate details
./scripts/manage-prod.sh cert-info

# Manual renewal (if needed)
./scripts/manage-prod.sh cert-renew
```

## Backup & Restore

### Backup

```bash
./scripts/manage-prod.sh backup
# Creates: backups/almeyo_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Restore

```bash
./scripts/manage-prod.sh restore backups/almeyo_backup_20250219_120000.tar.gz
```

## Common Tasks

### Restart a Service

```bash
# Specific service
./scripts/manage-prod.sh restart nginx

# All services
./scripts/manage-prod.sh restart
```

### View Logs

```bash
# Follow nginx logs
docker-compose -f docker-compose.prod.ssl.yml logs -f nginx

# View backend errors
./scripts/manage-prod.sh logs backend 50
```

### Update Code

```bash
./scripts/manage-prod.sh update
# Pulls latest code and rebuilds containers
```

### Emergency Stop

```bash
./scripts/manage-prod.sh stop
# Stops all services (brings site offline)
```

## Automatic Certificate Renewal

Certbot automatically renews certificates 30 days before expiry.

For automatic renewal via cron:

```bash
# Edit crontab
crontab -e

# Add line (runs daily at 3 AM):
0 3 * * * cd /path/to/almeyo-deploy && docker-compose -f docker-compose.prod.ssl.yml exec -T certbot certbot renew --quiet
```

## Troubleshooting

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues:
- DNS not ready
- Certificate validation failures
- Service health issues
- Rate limiting errors
- SSL handshake failures

## Directory Structure Details

### Nginx Configuration

**Production (SSL):**
- `nginx/nginx.conf` - Main config with TLS settings
- `nginx/conf.d/almeyo.conf` - Server block with security headers

**HTTP-Only (Initial):**
- `nginx/nginx.conf.init` - Minimal HTTP config
- `nginx/conf.d.init/almeyo.conf` - Simple HTTP server block

### Docker Volumes

| Volume | Purpose | Mount |
|--------|---------|-------|
| `backend_data` | Database files | `/app/data` |
| `backend_logs` | Application logs | `/app/logs` |
| `nginx_certs` | SSL certificates | `/etc/letsencrypt` |

### Docker Network

All services communicate via `almeyo-network` bridge network:
- Backend: `http://backend:3000`
- Frontend: `http://frontend:80`
- Nginx: Accessible on ports 80/443

## Support

For deployment issues:

1. **Check logs:** `./scripts/manage-prod.sh logs`
2. **Run health check:** `./scripts/manage-prod.sh health-check`
3. **Review troubleshooting:** See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
4. **Contact:** Check Let's Encrypt logs or Docker logs

## Production Checklist

- [ ] DNS A record points to server IP
- [ ] Firewall allows ports 80 and 443
- [ ] .env configured with domain and email
- [ ] Step 1 (deploy-init.sh) completed successfully
- [ ] DNS propagated (wait 24-48 hours)
- [ ] Step 2 (deploy-ssl.sh) completed successfully
- [ ] HTTPS working (https://your-domain.com)
- [ ] Certificate auto-renewal configured
- [ ] Backup strategy in place
- [ ] Monitoring enabled

## Related Repositories

- **almeyo-backend** - API and database
- **almeyo-frontend** - Web interface

---

**Last Updated:** February 2025
**Version:** 1.0


