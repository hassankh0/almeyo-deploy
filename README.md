# Almeyo Production Deployment

Production-grade Docker Compose deployment for Almeyo, based on best practices from the Olivié project.

## 📋 What's New (v1.0)

This upgraded deployment includes:

✅ **Optimized Docker Images**
- Multi-stage builds for minimal size
- Non-root container execution
- Production-only dependencies

✅ **Production-Ready Nginx**
- Reverse proxy with SSL/TLS support
- Gzip compression and caching
- Rate limiting and security headers
- Connection pooling and optimization

✅ **Health Checks & Monitoring**
- Automatic service health monitoring
- Self-healing with auto-restart
- Comprehensive logging

✅ **Resource Management**
- Memory limits and reservations
- Log rotation to prevent disk fill
- Docker volume persistence

✅ **Easy Deployment**
- Automated deployment scripts (Bash & PowerShell)
- Quick reference guides
- Comprehensive documentation

✅ **Security First**
- Secrets in .gitignore
- Non-root users in containers
- Security headers in Nginx

## 📁 Repository Structure

```
almeyo-deploy/
├── docker-compose.prod.yml           # Main production config
├── nginx/
│   ├── nginx.prod.conf               # Production Nginx config
│   └── conf.d.prod/                  # Additional configs
├── scripts/
│   ├── deploy.sh                     # Linux/Mac deployment
│   └── deploy.ps1                    # Windows deployment
├── .env.prod                         # Production secrets (DO NOT COMMIT)
├── .env.prod.example                 # Template
├── .gitignore                        # Prevents committing secrets
├── README.md                         # This file
├── PRODUCTION_DEPLOYMENT.md          # Complete guide
├── QUICK_REFERENCE_PROD.md           # Common commands
├── INFRASTRUCTURE_SUMMARY.md         # Technical details
└── QUICK_COMMANDS.sh                 # Quick utilities
```

## ⚡ Quick Start

### Prerequisites
- Docker 20.10+ and Docker Compose 2.0+
- 2GB free disk space
- Ports 80 and 443 available
- Domain with DNS A record pointing to your server

### 1. Prepare Environment

```bash
# Copy environment template
cp .env.prod.example .env.prod

# Edit with your values
nano .env.prod  # or use your favorite editor
```

Update these critical values:
- `DOMAIN` - Your production domain
- `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS` - Email config
- `CERT_EMAIL` - For SSL certificate notifications

### 2. Deploy (Choose One)

**Using Script (Recommended):**

Linux/Mac:
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh deploy
```

Windows PowerShell:
```powershell
.\scripts\deploy.ps1
```

**Manual:**

## ⚙️ Key Operations

### View Status
```bash
docker compose -f docker-compose.prod.yml ps
```

### View Logs
```bash
docker compose -f docker-compose.prod.yml logs -f backend
```

### Backup Database
```bash
docker cp almeyo-backend:/app/data/almeyo.db ./backups/almeyo.db.backup
```

### Restart Services
```bash
docker compose -f docker-compose.prod.yml restart backend
```

### Stop All
```bash
docker compose -f docker-compose.prod.yml down
```

See [QUICK_REFERENCE_PROD.md](./QUICK_REFERENCE_PROD.md) for more commands.

## 🔧 Configuration Files

### docker-compose.prod.yml
Main orchestration file with:
- 3 production services
- Health checks for each
- Memory/CPU limits
- Volume persistence
- Logging configuration
- Internal networking

### nginx/nginx.prod.conf
Nginx main configuration:
- Security headers
- Rate limiting zones
- Gzip compression
- Upstream backends
- SSL/TLS settings (commented, uncomment to enable)

### Backend: Dockerfile.prod
Optimized Node.js image:
- Multi-stage build
- Production dependencies only
- Non-root user execution
- Health checks
- Dumb-init for proper signal handling

### Frontend: Dockerfile.prod
Optimized Nginx image:
- Alpine Linux base
- Security updates
- Health checks
- Non-root execution

## 🌐 Deployment Paths

| URL | Service | Content |
|-----|---------|---------|
| `http://localhost/` | Frontend | HTML files |
| `http://localhost/api` | Backend | REST API |
| `http://localhost/public/images` | Backend | User uploads |

## 📊 Resource Usage

**Memory Allocation:**
- Backend: 512M limit (processes), 256M reserved
- Frontend: 256M limit, 128M reserved
- Nginx: 256M limit, 128M reserved
- **Total: 1GB limit, 512M minimum**

Adjust in `docker-compose.prod.yml` if needed:
```yaml
deploy:
  resources:
    limits:
      memory: 512M
```

## 📋 Maintenance Checklist

- [ ] Daily: Check service health (`docker compose ps`)
- [ ] Daily: Review error logs
- [ ] Weekly: Backup database
- [ ] Weekly: Check disk usage
- [ ] Monthly: Review resource usage (`docker stats`)
- [ ] Quarterly: Test backup restore
- [ ] Quarterly: Update Docker images

## 🆘 Troubleshooting

**Services won't start?**
```bash
docker compose -f docker-compose.prod.yml logs
```

**High memory usage?**
```bash
docker stats
```

**Port 80 already in use?**
```bash
lsof -i :80
# Or change port in docker-compose.prod.yml
```

See [QUICK_REFERENCE_PROD.md](./QUICK_REFERENCE_PROD.md) for more troubleshooting.

## 🔐 Important Security Notes

1. **Never commit .env.prod** - Keep it in .gitignore
2. **Use HTTPS in production** - Follow HTTPS setup guide
3. **Backup regularly** - Daily database backups recommended
4. **Monitor logs** - Check for errors and suspicious activity
5. **Keep images updated** - Rebuild periodically for security patches

## 🔄 SSL/TLS Setup (HTTPS)

To enable HTTPS:

1. Uncomment HTTPS server block in `nginx/nginx.prod.conf`
2. Get SSL certificate with Certbot
3. Restart Nginx: `docker compose restart nginx`
4. Set up auto-renewal cron job

See [PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md#ssltls-configuration-https) for detailed steps.

## 📞 Support

For issues or questions:

1. Check [QUICK_REFERENCE_PROD.md](./QUICK_REFERENCE_PROD.md) for common commands
2. Review [PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md) for detailed documentation
3. Check `docker compose logs` for error details
4. Review application logs in `./backups/logs_*/`

## 🎯 What Changed from v0

| Feature | v0 (Basic) | v1 (Production) |
|---------|-----------|-----------------|
| Docker Files | Single Dockerfile | Dockerfile.prod (optimized) |
| Compose File | Basic setup | Production-grade config |
| Health Checks | Simple | Comprehensive with timeouts |
| Resource Limits | None | Memory/CPU limits set |
| Logging | Console | Rotated files with size limits |
| Nginx | inline | Separate prod config |
| Documentation | Minimal | Comprehensive guides |
| Scripts | None | Automated deploy scripts |
| Security | Basic | Production-hardened |

## ✨ Based On

This production deployment is based on best practices from the **Olivié** project, specifically adapted for Almeyo's Node.js/SQLite stack.

Key improvements:
- Production-optimized Docker images
- Comprehensive Nginx configuration
- Resource management and monitoring
- Automated deployment tooling
- Complete documentation

## 📅 Version History

- **v1.0** (Feb 2024) - Production-grade deployment
  - Multi-stage Docker builds
  - Automated deployment scripts  
  - Comprehensive documentation
  - Health checks and monitoring
  - Resource limits and management

---

**For questions or feedback**, refer to the detailed documentation files or check the application repository.

**Ready to deploy?** Start with [PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md)
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


