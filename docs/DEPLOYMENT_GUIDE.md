# Deployment Guide - Almeyo Restaurant

Complete step-by-step guide for deploying Almeyo to production.

## Prerequisites

### Server Requirements
- **OS:** Linux (Ubuntu 20.04+ recommended)
- **CPU:** 2+ cores
- **RAM:** 4GB minimum (8GB recommended)
- **Storage:** 20GB free space
- **Network:** Public IP address, ports 80/443 open

### Software Requirements
- Docker Engine 20.10+
- Docker Compose 1.29+
- Git (for pulling code)
- curl (for health checks)

### Domain Requirements
- Valid domain (e.g., almeyo.com)
- DNS A record pointing to server IP
- Email for Let's Encrypt notifications

### Installation

```bash
# Install Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

## Step 1: Initial HTTP Deployment

### 1.1 Prepare Directory

```bash
# Clone deployment repository
cd /home/almeyo  # or your preferred directory
git clone <your-repo-url> almeyo-deploy
cd almeyo-deploy

# Make scripts executable
chmod +x scripts/*.sh

# Create environment file
cp .env.prod.example .env
nano .env  # Edit with your configuration
```

### 1.2 Configure Environment

Edit `.env` with these values:

```bash
DOMAIN=almeyo.com              # Your domain name
CERT_EMAIL=admin@almeyo.com    # Email for Let's Encrypt
SMTP_HOST=smtp.gmail.com       # Email SMTP server
SMTP_PORT=587                  # SMTP port
SMTP_USER=your-email@gmail.com # Your email
SMTP_PASS=your-app-password    # App-specific password
NODE_ENV=production            # Environment
```

**Gmail Setup (if using Gmail):**
1. Go to https://myaccount.google.com/apppasswords
2. Select Mail and Device
3. Copy the 16-character password
4. Paste into SMTP_PASS in .env

### 1.3 Run Initial Deployment

```bash
./scripts/deploy-init.sh
```

This script will:
- ✓ Check Docker installation
- ✓ Create required directories
- ✓ Build backend and frontend images
- ✓ Start services (without SSL)
- ✓ Test HTTP connectivity
- ✓ Display next steps

**Expected Output:**
```
✓ Docker is installed
✓ Services are running
✓ Directory structure created
✓ Backend image built
✓ Frontend image built
✓ HTTP connection successful
✓ Initial deployment complete!
```

### 1.4 Verify HTTP Deployment

```bash
# Test local access
curl http://localhost/

# Check container status
docker-compose -f docker-compose.prod.init.yml ps

# View logs
docker-compose -f docker-compose.prod.init.yml logs -f
```

## Step 2: DNS Configuration

### 2.1 Update DNS Records

Get your server's IP address:

```bash
# Find server IP
hostname -I
# or
ip addr show | grep "inet "
```

Update your domain's DNS A record:

| Type | Name | Value |
|------|------|-------|
| A | almeyo.com | your.server.ip |
| A | www.almeyo.com | your.server.ip |

### 2.2 Wait for DNS Propagation

```bash
# Check DNS propagation (wait until returns your IP)
nslookup almeyo.com

# Check multiple times over 24-48 hours
# Stop when it returns your server's IP address
```

### 2.3 Verify DNS is Ready

```bash
# From your server, test DNS resolution
curl http://almeyo.com/

# Should return the Almeyo homepage
```

**⚠️ Do NOT proceed to Step 3 until DNS is fully propagated and returns your server IP!**

## Step 3: SSL Deployment

### 3.1 Run SSL Deployment Script

Once DNS is ready:

```bash
cd /home/almeyo/almeyo-deploy
./scripts/deploy-ssl.sh
```

This script will:
- ✓ Stop HTTP-only deployment
- ✓ Create SSL configurations
- ✓ Request Let's Encrypt certificate
- ✓ Verify certificate
- ✓ Start services with SSL
- ✓ Setup auto-renewal
- ✓ Test HTTPS connectivity

**Expected Output:**
```
✓ Services stopped
✓ Created webroot directories
✓ SSL certificate obtained successfully
✓ Certificate verified
✓ HTTPS connection successful
✓ SSL deployment complete!
```

### 3.2 Verify HTTPS Deployment

```bash
# Test HTTPS access
curl -k https://localhost/

# Test from another machine
curl https://almeyo.com/

# Check certificate
openssl s_client -connect almeyo.com:443 -showcerts

# Verify in browser: https://almeyo.com/
```

## Step 4: Production Monitoring

### 4.1 Setup Monitoring

```bash
# Run health checks
./scripts/manage-prod.sh health-check

# View service status
./scripts/manage-prod.sh status

# Check logs
./scripts/manage-prod.sh logs
```

### 4.2 Setup Automatic Backups

```bash
# Create backup
./scripts/manage-prod.sh backup

# Schedule daily backups (add to crontab)
crontab -e

# Add this line:
0 2 * * * cd /home/almeyo/almeyo-deploy && ./scripts/manage-prod.sh backup
```

### 4.3 Monitor Certificate Expiry

```bash
# Check certificate expiry
./scripts/manage-prod.sh cert-info

# Certificate auto-renews 30 days before expiry
# No manual action needed normally
```

### 4.4 Setup Log Monitoring

```bash
# View nginx logs
docker-compose -f docker-compose.prod.ssl.yml logs -f nginx

# View backend logs
docker-compose -f docker-compose.prod.ssl.yml logs -f backend

# View all logs
./scripts/manage-prod.sh logs
```

## Step 5: Post-Deployment Tasks

### 5.1 Test All Functionality

- [ ] Visit https://almeyo.com in browser
- [ ] Test menu loading
- [ ] Test contact form
- [ ] Test reservation system
- [ ] Test image gallery
- [ ] Verify SSL certificate (green lock)
- [ ] Test on mobile devices

### 5.2 SSL Security Verification

```bash
# Check SSL rating
# Visit: https://www.ssllabs.com/ssltest/?d=almeyo.com
# Should get A+ rating
```

### 5.3 Search Engine Setup

```bash
# Submit sitemap to Google
# 1. Go to Google Search Console
# 2. Add property: https://almeyo.com
# 3. Submit sitemap: https://almeyo.com/sitemap.xml
# 4. Monitor indexing and errors
```

### 5.4 Email Verification

```bash
# Test email notifications
# 1. Edit backend code to send test email
# 2. Verify SMTP is working
# 3. Check email logs
```

## Daily Operations

### Check Service Health

```bash
# Quick health check
./scripts/manage-prod.sh health-check

# Detailed status
./scripts/manage-prod.sh status

# View recent logs
./scripts/manage-prod.sh logs backend 20
```

### Common Tasks

```bash
# Restart all services
./scripts/manage-prod.sh restart

# Restart specific service (nginx, backend, frontend, certbot)
./scripts/manage-prod.sh restart nginx

# Create database backup
./scripts/manage-prod.sh backup

# View certificate info
./scripts/manage-prod.sh cert-info

# Update code
./scripts/manage-prod.sh update
```

## Maintenance Schedule

### Daily
- [ ] Run health checks: `./scripts/manage-prod.sh health-check`
- [ ] Review error logs: `./scripts/manage-prod.sh logs`

### Weekly
- [ ] Create backup: `./scripts/manage-prod.sh backup`
- [ ] Review certificate: `./scripts/manage-prod.sh cert-info`

### Monthly
- [ ] Update dependencies: `./scripts/manage-prod.sh update`
- [ ] Test backup restoration
- [ ] Review Google Search Console

### Quarterly
- [ ] Review security settings
- [ ] Check SSL/TLS configuration
- [ ] Audit database

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for:
- DNS not ready errors
- Certificate validation failures
- Service startup issues
- Health check failures
- Connection refused errors
- Rate limiting issues

## Backup & Recovery

### Create Backup

```bash
./scripts/manage-prod.sh backup
# Creates: backups/almeyo_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Restore from Backup

```bash
./scripts/manage-prod.sh restore backups/almeyo_backup_20250219_120000.tar.gz
```

### Full System Recovery

```bash
# 1. Stop services
./scripts/manage-prod.sh stop

# 2. Restore backup
./scripts/manage-prod.sh restore <backup_file>

# 3. Restart services
./scripts/manage-prod.sh restart

# 4. Verify
./scripts/manage-prod.sh health-check
```

## Emergency Procedures

### Service Down

```bash
# Check status
./scripts/manage-prod.sh status

# View logs
./scripts/manage-prod.sh logs

# Restart affected service
./scripts/manage-prod.sh restart nginx

# If still down, restart all
./scripts/manage-prod.sh restart
```

### Disk Full

```bash
# Check disk space
df -h

# Clean old logs
docker-compose -f docker-compose.prod.ssl.yml logs --tail=100 > /tmp/logs.txt

# Remove old backups
rm backups/almeyo_backup_* -v | head -10
```

### Certificate Renewal Failed

```bash
# Check current certificate
./scripts/manage-prod.sh cert-info

# Manually renew
./scripts/manage-prod.sh cert-renew

# View certbot logs
docker-compose -f docker-compose.prod.ssl.yml logs certbot
```

## Performance Optimization

### Enable HTTP/2

Already configured in Nginx:
```nginx
listen 443 ssl http2;
```

### Enable gzip Compression

Already configured (compression level 6).

### Cache Static Assets

Already configured:
- Images: 30 days cache
- HTML: Not cached (always fresh)

### Monitor Performance

```bash
# Check Nginx status
curl http://localhost/nginx_status

# Monitor resource usage
docker stats

# Check response times
curl -w "@curl-format.txt" https://almeyo.com/
```

## Security Hardening

### Review Current Security

```bash
# SSL test
curl -I https://almeyo.com

# Check headers
curl -I https://almeyo.com | grep -i "strict-transport"
```

### Enable Additional Security

Already configured:
- ✓ TLS 1.2+ only
- ✓ HSTS headers
- ✓ CSP headers
- ✓ Security headers
- ✓ Rate limiting

## Conclusion

Your Almeyo production deployment is now complete!

**Key Files:**
- `almeyo-deploy/docker-compose.prod.ssl.yml` - Production config
- `almeyo-deploy/scripts/manage-prod.sh` - Daily operations

**Support Resources:**
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Let's Encrypt Help](https://letsencrypt.org/docs/)
- [Git-fu](https://git-scm.com/doc)

---
Last Updated: February 2025
