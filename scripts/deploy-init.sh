#!/bin/bash

################################################################################
# ALMEYO INITIAL DEPLOYMENT SCRIPT
# Step 1: Deploy without SSL (for ACME challenge)
# Usage: ./deploy-init.sh
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

# Check if Docker is installed
check_docker() {
    print_header "Checking Docker Installation"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        echo "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker is installed: $(docker --version)"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker Compose is not installed"
        echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    print_success "Docker Compose is installed: $(docker compose version)"
}

# Setup environment
setup_environment() {
    print_header "Setting Up Environment"
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.prod.example" ]; then
            print_info "Creating .env from .env.prod.example"
            cp .env.prod.example .env
            print_warning "Please edit .env and enter your configuration"
            print_warning "Required: DOMAIN, CERT_EMAIL, SMTP credentials"
            read -p "Press Enter once you've configured .env..."
        else
            print_error ".env.prod.example not found"
            exit 1
        fi
    else
        print_success ".env file exists"
    fi
    
    # Create required directories
    mkdir -p ./nginx/certbot-webroot
    mkdir -p ./certbot
    mkdir -p ./logs
    
    print_success "Directory structure created"
}

# Load environment variables
load_env() {
    # Load .env file
    if [ -f ".env" ]; then
        export $(cat .env | grep -v '^#' | xargs)
    fi
}

# Build Docker images
build_images() {
    print_header "Building Docker Images"
    
    print_info "Building backend image..."
    docker compose -f docker-compose.prod.init.yml build backend
    print_success "Backend image built"
    
    print_info "Building frontend image..."
    docker compose -f docker-compose.prod.init.yml build frontend
    print_success "Frontend image built"
}

# Start services
start_services() {
    print_header "Starting Services (HTTP only)"
    
    print_info "Starting backend, frontend, and nginx..."
    docker compose -f docker-compose.prod.init.yml up -d
    
    print_info "Waiting for services to be healthy..."
    sleep 5
    
    # Check service health
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker compose -f docker-compose.prod.init.yml ps | grep -q "healthy"; then
            print_success "Services are running"
            break
        else
            print_info "Waiting for services... ($attempt/$max_attempts)"
            sleep 2
            attempt=$((attempt + 1))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_warning "Services may not be fully ready yet"
    fi
}

# Test HTTP connectivity
test_http() {
    print_header "Testing HTTP Connectivity"
    
    print_info "Testing HTTP connection to localhost:80..."
    
    if curl -f http://localhost/ > /dev/null 2>&1; then
        print_success "HTTP connection successful"
    else
        print_warning "HTTP connection test did not respond immediately"
        print_info "Services might still be initializing"
    fi
    
    print_info "Testing API endpoint..."
    if curl -f http://localhost/api/health > /dev/null 2>&1; then
        print_success "API health check passed"
    else
        print_warning "API health check not responding yet"
    fi
}

# Display container status
show_status() {
    print_header "Container Status"
    docker compose -f docker-compose.prod.init.yml ps
}

# Display logs
show_logs() {
    print_header "Recent Logs"
    echo "To view logs, use:"
    echo "  docker compose -f docker-compose.prod.init.yml logs -f"
}

# Display next steps
next_steps() {
    print_header "Next Steps - IMPORTANT"
    
    echo "Step 1: Configure your DNS"
    echo "  └─ Point your domain to this server's IP address"
    echo "  └─ Update DNS A record: ${DOMAIN:-almeyo.com} → your-server-ip"
    echo "  └─ Wait for DNS propagation (24-48 hours recommended)"
    echo ""
    echo "Step 2: Verify HTTP access"
    echo "  └─ Once DNS is ready, test: curl http://${DOMAIN:-almeyo.com}/"
    echo "  └─ You should see the Almeyo website homepage"
    echo ""
    echo "Step 3: Obtain SSL Certificate"
    echo "  └─ Run the SSL deployment script:"
    echo "  └─ ./deploy-ssl.sh"
    echo ""
    echo "Step 4: Manage Production Services"
    echo "  └─ Use ./manage-prod.sh for daily operations"
    echo "  └─ Check logs: ./manage-prod.sh logs"
    echo "  └─ Health check: ./manage-prod.sh health-check"
    echo ""
    echo "Useful Commands:"
    echo "  View logs:         docker compose -f docker-compose.prod.init.yml logs -f"
    echo "  Check containers:  docker compose -f docker-compose.prod.init.yml ps"
    echo "  Restart services:  docker compose -f docker-compose.prod.init.yml restart"
    echo "  Stop services:     docker compose -f docker-compose.prod.init.yml down"
    echo ""
}

# Main
main() {
    clear
    print_header "ALMEYO INITIAL DEPLOYMENT"
    echo "This script will deploy Almeyo without SSL (HTTP only)"
    echo "Next step: Run deploy-ssl.sh after DNS is ready"
    echo ""
    
    check_docker
    setup_environment
    load_env
    build_images
    start_services
    sleep 2
    test_http
    show_status
    show_logs
    next_steps
    
    print_success "Initial deployment complete!"
    print_info "Services are running in HTTP mode and ready for SSL setup"
}

# Run main function
main "$@"
