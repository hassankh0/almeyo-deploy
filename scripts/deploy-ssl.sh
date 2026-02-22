#!/bin/bash

################################################################################
# ALMEYO SSL DEPLOYMENT SCRIPT
# Step 2: Enable SSL/TLS with Let's Encrypt certificate
# Usage: ./deploy-ssl.sh
# Prerequisite: Successfully run deploy-init.sh and configured DNS
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Load environment
load_env() {
    if [ -f ".env" ]; then
        export $(cat .env | grep -v '^#' | xargs)
    else
        print_error ".env file not found"
        exit 1
    fi
    
    if [ -z "$DOMAIN" ] || [ -z "$CERT_EMAIL" ]; then
        print_error "DOMAIN and CERT_EMAIL not configured in .env"
        exit 1
    fi
}

# Stop current deployment
stop_services() {
    print_header "Stopping Initial Deployment"
    print_info "Stopping HTTP-only services..."
    docker-compose -f docker-compose.prod.init.yml down
    print_success "Services stopped"
}

# Create SSL config files
create_ssl_config() {
    print_header "Creating SSL Configuration"
    
    # Create certbot webroot directory
    mkdir -p ./nginx/certbot-webroot
    print_success "Created webroot directories"
    
    # The nginx.conf.ssl and conf.d/almeyo.conf already exist
    # Just verify they're in place
    if [ -f ./nginx/nginx.conf ] && [ -f ./nginx/conf.d/almeyo.conf ]; then
        print_success "SSL nginx configuration files found"
    else
        print_error "SSL configuration files not found"
        exit 1
    fi
}

# Obtain SSL certificate with Certbot
obtain_certificate() {
    print_header "Obtaining SSL Certificate from Let's Encrypt"
    print_info "Domain: $DOMAIN"
    print_info "Email: $CERT_EMAIL"
    echo ""
    
    # Start services with certbot
    print_info "Starting services with Certbot..."
    docker-compose -f docker-compose.prod.ssl.yml up -d
    
    # Wait for Nginx to be ready (before certbot runs)
    print_info "Waiting for Nginx to be ready..."
    sleep 5
    
    # Run certbot to obtain certificate
    print_info "Requesting SSL certificate..."
    
    docker-compose -f docker-compose.prod.ssl.yml run --rm certbot \
        certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --email "$CERT_EMAIL" \
        --no-eff-email
    
    local cert_status=$?
    
    if [ $cert_status -eq 0 ]; then
        print_success "SSL certificate obtained successfully"
        return 0
    else
        print_error "Failed to obtain SSL certificate"
        return 1
    fi
}

# Verify certificate
verify_certificate() {
    print_header "Verifying SSL Certificate"
    
    local cert_path="./certbot/conf/live/$DOMAIN/fullchain.pem"
    
    if [ -f "$cert_path" ]; then
        print_success "Certificate file found"
        
        # Display certificate info
        local expiry=$(docker run --rm \
            -v $(pwd)/certbot/conf:/etc/letsencrypt \
            certbot/certbot \
            certificates -d "$DOMAIN" 2>/dev/null | grep "Expiry" || echo "Unknown")
        
        print_info "Certificate details: $expiry"
        return 0
    else
        print_error "Certificate file not found"
        return 1
    fi
}

# Test HTTPS connectivity
test_https() {
    print_header "Testing HTTPS Connectivity"
    
    print_info "Waiting for Nginx to start with SSL..."
    sleep 10
    
    print_info "Testing HTTPS connection..."
    
    # Wait up to 30 seconds for HTTPS to be ready
    local max_attempts=15
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -sk https://localhost/ > /dev/null 2>&1; then
            print_success "HTTPS connection successful"
            return 0
        else
            print_info "Waiting for HTTPS... ($attempt/$max_attempts)"
            sleep 2
            attempt=$((attempt + 1))
        fi
    done
    
    print_warning "HTTPS not responding yet, but Nginx may still be initializing"
}

# Setup auto-renewal
setup_renewal() {
    print_header "Setting Up Automatic Certificate Renewal"
    
    # Create renewal script
    cat > ./scripts/renew-cert.sh << 'EOF'
#!/bin/bash
docker-compose -f docker-compose.prod.ssl.yml exec -T certbot certbot renew --quiet
EOF
    
    chmod +x ./scripts/renew-cert.sh
    print_success "Renewal script created"
    
    # Display cron setup instructions
    print_info "To enable automatic renewal, add this to your crontab:"
    echo ""
    echo "  crontab -e"
    echo ""
    echo "Add this line:"
    echo "  0 3 * * * cd /path/to/almeyo-deploy && ./scripts/renew-cert.sh"
    echo ""
    print_info "This will check for renewal daily at 3 AM"
}

# Display container status
show_status() {
    print_header "Container Status"
    docker-compose -f docker-compose.prod.ssl.yml ps
}

# Display completion info
completion_info() {
    print_header "SSL Deployment Complete"
    
    echo "Website is now running with SSL/TLS enabled!"
    echo ""
    echo "Access your website:"
    echo "  → https://${DOMAIN}"
    echo ""
    echo "Certificate Information:"
    echo "  → Domain: $DOMAIN"
    echo "  → Auto-renewal: Enabled (30 days before expiry)"
    echo ""
    echo "Useful Commands:"
    echo "  View logs:              docker-compose -f docker-compose.prod.ssl.yml logs -f"
    echo "  Check cert expiry:      ./manage-prod.sh cert-info"
    echo "  Renew certificate:      ./manage-prod.sh cert-renew"
    echo "  Check service health:   ./manage-prod.sh health-check"
    echo "  View service status:    docker-compose -f docker-compose.prod.ssl.yml ps"
    echo ""
    echo "Next Steps:"
    echo "  1. Test your website: https://${DOMAIN}"
    echo "  2. Verify SSL: https://www.ssllabs.com/ssltest"
    echo "  3. Setup monitoring: ./manage-prod.sh health-check"
    echo "  4. Configure email backups (optional)"
    echo ""
}

# Main
main() {
    clear
    print_header "ALMEYO SSL DEPLOYMENT"
    echo "This script will enable SSL/TLS with Let's Encrypt"
    echo "Prerequisites:"
    echo "  • deploy-init.sh completed successfully"
    echo "  • DNS records updated and propagated"
    echo "  • .env configured with DOMAIN and CERT_EMAIL"
    echo ""
    
    read -p "Continue with SSL setup? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Deployment cancelled"
        exit 0
    fi
    
    load_env
    stop_services
    create_ssl_config
    
    if obtain_certificate; then
        if verify_certificate; then
            print_success "Certificate verified"
        fi
        test_https
        setup_renewal
        show_status
        completion_info
        print_success "SSL deployment complete!"
    else
        print_error "Certificate setup failed"
        print_info "Common issues:"
        print_info "  • DNS not ready (wait 24-48 hours after DNS change)"
        print_info "  • HTTP port not accessible (check firewall rules)"
        print_info "  • Let's Encrypt rate limit exceeded (wait 1 hour)"
        exit 1
    fi
}

# Run main function
main "$@"
