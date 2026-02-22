# Troubleshooting Guide

Common issues and solutions for Almeyo deployment.

## DNS Issues

### Problem: DNS doesn't resolve

```
Error: Failed to resolve hostname
nslookup: can't resolve 'almeyo.com'
```

**Solution:**
```bash
# Check DNS records
nslookup almeyo.com
dig almeyo.com

# May take 24-48 hours to propagate
# Check status: https://www.whatsmydns.net/?d=almeyo.com
```

### Problem: Certificate validation fails

```
Error: Failed to verify self.example.com for TLS-SNI-01
Challenge failed authorization procedure
```

**Causes:**
- DNS not ready yet
- Firewall blocking port 80
- Web server not responding to ACME challenges

**Solution:**
```bash
# 1. Verify HTTP is accessible
curl http://almeyo.com/

# 2. Check firewall allows port 80
telnet almeyo.com 80

# 3. Verify DNS A record points to server IP
nslookup almeyo.com

# 4. Wait for full DNS propagation (24-48 hours)

# 5. Retry deployment
./scripts/deploy-ssl.sh
```

## Certificate Issues

### Problem: Certificate not found

```
Error: Certificate file not found
/etc/letsencrypt/live/almeyo.com/fullchain.pem
```

**Solution:**
```bash
# Check if deploy-ssl.sh completed successfully
./scripts/manage-prod.sh cert-info

# If missing, run SSL deployment
./scripts/deploy-ssl.sh

# Check certbot logs
docker-compose -f docker-compose.prod.ssl.yml logs certbot
```

### Problem: Certificate about to expire

**Solution:**
```bash
# Manual renewal
./scripts/manage-prod.sh cert-renew

# Check status
./scripts/manage-prod.sh cert-info

# Auto-renewal should handle this automatically 30 days before expiry
```

### Problem: SSL handshake failure

```
Error: SSL: CERTIFICATE_VERIFY_FAILED
```

**Solution:**
```bash
# Check if certificate exists and is valid
openssl s_client -connect almeyo.com:443 -showcerts

# Verify Nginx is serving correct certificate
./scripts/manage-prod.sh logs nginx

# Check certificate path in nginx config
grep ssl_certificate nginx/conf.d/almeyo.conf
```

## Service Issues

### Problem: Backend service won't start

```
Error: backend exited with code 1
```

**Solution:**
```bash
# Check logs
./scripts/manage-prod.sh logs backend 50

# Common issues:
# 1. Port already in use
netstat -tln | grep 3000

# 2. Database file permissions
docker-compose -f docker-compose.prod.ssl.yml run backend ls -la /app/data/

# 3. Restart service
./scripts/manage-prod.sh restart backend
```

### Problem: Frontend service crashing

```
Error: frontend exited with code 132
```

**Solution:**
```bash
# View logs
./scripts/manage-prod.sh logs frontend 50

# Restart
./scripts/manage-prod.sh restart frontend

# Check if HTML files are correct
docker-compose -f docker-compose.prod.ssl.yml run frontend ls /usr/share/nginx/html/
```

### Problem: Nginx returns 502 Bad Gateway

```
Error: 502 Bad Gateway
Failed to connect to backend
```

**Solution:**
```bash
# Check if backend is running
./scripts/manage-prod.sh status

# Test backend health
curl http://localhost:3000/api/health

# Check docker network
docker network ls
docker network inspect almeyo-network

# Restart services
./scripts/manage-prod.sh restart

# Check nginx logs
./scripts/manage-prod.sh logs nginx 50
```

### Problem: Service stuck in "unhealthy" state

```
Status: Unhealthy
```

**Solution:**
```bash
# Check what health check is failing
docker-compose -f docker-compose.prod.ssl.yml ps

# View detailed logs
./scripts/manage-prod.sh logs backend 100

# Restart specific service
./scripts/manage-prod.sh restart backend

# If persists, restart all
./scripts/manage-prod.sh restart
```

## Network Issues

### Problem: Cannot connect to localhost

```
Error: Connection refused
telnet: connect: Connection refused
```

**Solution:**
```bash
# Check if containers are running
docker ps | grep almeyo

# Check if nginx is listening
docker-compose -f docker-compose.prod.ssl.yml exec nginx netstat -tln | grep LISTEN

# Verify port bindings
docker port almeyo-nginx

# Restart nginx
./scripts/manage-prod.sh restart nginx
```

### Problem: Rate limiting being triggered

```
Error: 429 Too Many Requests
```

**Solution:**
```bash
# Cause: More than 10 requests per second per IP

# 1. Check if there's a DDoS
./scripts/manage-prod.sh logs nginx | grep "429"

# 2. Whitelist trusted IPs (edit nginx config)
vim nginx/conf.d/almeyo.conf

# 3. Adjust rate limit if needed
# Change: limit_req_zone ... rate=10r/s
# To higher value
```

## Performance Issues

### Problem: Website slow

**Solution:**
```bash
# 1. Check server resources
docker stats

# 2. Monitor response times
curl -w "Time: %{time_total}s\n" https://almeyo.com/

# 3. Check for bottlenecks
./scripts/manage-prod.sh logs nginx 20 | grep "upstream"

# 4. Verify cache is working
curl -I https://almeyo.com/images/logo.png | grep "Cache-Control"

# 5. Restart services
./scripts/manage-prod.sh restart
```

### Problem: Database queries slow

**Solution:**
```bash
# Check backend logs for slow queries
docker-compose -f docker-compose.prod.ssl.yml logs backend | grep "slow"

# Restart backend
./scripts/manage-prod.sh restart backend

# Check database file size
docker run --rm -v almeyo_backend_data:/data alpine du -sh /data/
```

## Storage Issues

### Problem: Disk space full

```
Error: write: No space left on device
```

**Solution:**
```bash
# Check disk usage
df -h

# Identify large files
du -sh * | sort -h | tail

# Clean old logs
journalctl --vacuum=100M

# Remove old backups (keep recent ones)
ls -lh backups/ | head -20
rm backups/almeyo_backup_202501* -v  # Remove January backups

# Clean Docker images
docker image prune -a

# Clean Docker volumes (⚠️ be careful)
docker volume prune
```

### Problem: Database corruption

```
Error: database disk image is malformed
```

**Solution:**
```bash
# 1. Stop services
./scripts/manage-prod.sh stop

# 2. Restore from backup
./scripts/manage-prod.sh restore backups/almeyo_backup_20250215_120000.tar.gz

# 3. Restart and verify
./scripts/manage-prod.sh restart
./scripts/manage-prod.sh health-check
```

## Configuration Issues

### Problem: Environment variables not loading

```
Error: DOMAIN is not set
```

**Solution:**
```bash
# Check .env file exists and readable
cat .env | head

# Reload environment
export $(cat .env | grep -v '^#' | xargs)

# Verify loaded
echo $DOMAIN
echo $CERT_EMAIL

# Restart services to pick up new env vars
./scripts/manage-prod.sh restart
```

### Problem: CORS errors

```
Error: Access to XMLHttpRequest blocked by CORS policy
```

**Solution:**
```bash
# Check backend CORS_ORIGIN in .env
grep CORS docker-compose.prod.ssl.yml

# Verify domain matches
# Should be: https://almeyo.com

# Restart backend to apply changes
./scripts/manage-prod.sh restart backend
```

## Backup Issues

### Problem: Backup file corrupted

```
Error: gzip: stdin: invalid compression method
```

**Solution:**
```bash
# Check backup file
file backups/almeyo_backup_*.tar.gz

# If corrupted, delete and create new
rm backups/almeyo_backup_corrupted.tar.gz
./scripts/manage-prod.sh backup
```

### Problem: Restore fails

```
Error: tar: unexpected EOF
```

**Solution:**
```bash
# Use previous backup
ls -lh backups/ | head -5

# Try restoring older backup
./scripts/manage-prod.sh restore backups/almeyo_backup_older.tar.gz

# If all backups corrupted:
# 1. Contact support
# 2. Restore from cloud backup
```

## Log Analysis

### Find error messages

```bash
# Backend errors
./scripts/manage-prod.sh logs backend | grep -i error

# Nginx errors  
./scripts/manage-prod.sh logs nginx | grep -i error

# All errors
./scripts/manage-prod.sh logs | grep -i error
```

### Monitor in real-time

```bash
# Follow all logs
docker-compose -f docker-compose.prod.ssl.yml logs -f

# Follow specific service
docker-compose -f docker-compose.prod.ssl.yml logs -f nginx

# Last 100 lines
./scripts/manage-prod.sh logs 100
```

## Getting Help

### Gather diagnostic information

```bash
# Create diagnostic bundle
./scripts/manage-prod.sh status > /tmp/status.txt
./scripts/manage-prod.sh health-check > /tmp/health.txt
docker-compose -f docker-compose.prod.ssl.yml logs > /tmp/logs.txt
uname -a > /tmp/system.txt

# Share these files with support
tar czf /tmp/almeyo-diagnostic.tar.gz \
  /tmp/status.txt \
  /tmp/health.txt \
  /tmp/logs.txt \
  /tmp/system.txt
```

### Common Log Locations

```bash
# Nginx access logs
docker-compose -f docker-compose.prod.ssl.yml exec nginx tail -f /var/log/nginx/access.log

# Nginx error logs
docker-compose -f docker-compose.prod.ssl.yml exec nginx tail -f /var/log/nginx/error.log

# Certbot logs
docker-compose -f docker-compose.prod.ssl.yml logs certbot

# Docker system logs
journalctl -xu docker -n 100
```

### Contact Support

When reporting issues, include:
1. Output of `./scripts/manage-prod.sh status`
2. Last 50 lines of logs: `./scripts/manage-prod.sh logs backend 50`
3. Error message (exact text)
4. Steps to reproduce
5. System info: `uname -a`

---
Last Updated: February 2025
