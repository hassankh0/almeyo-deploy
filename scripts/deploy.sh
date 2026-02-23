#!/bin/bash

# Almeyo Production Deployment Script
# This script builds and deploys Almeyo with Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENV_FILE=".env.prod"
DOCKER_COMPOSE_FILE="docker-compose.prod.yml"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose."
        exit 1
    fi
    
    # Check if .env.prod exists
    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env.prod file not found. Please create it from .env.prod.example"
        exit 1
    fi
    
    log_info "All prerequisites checked."
}

# Backup existing data
backup_data() {
    log_info "Backing up existing data..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
    fi
    
    # Get current container volumes (if they exist)
    CONTAINER_ID=$(docker ps -aq -f "name=almeyo-backend" 2>/dev/null || true)
    
    if [ -n "$CONTAINER_ID" ]; then
        log_info "Backing up database and logs..."
        docker cp almeyo-backend:/app/data "$BACKUP_DIR/data_$TIMESTAMP" 2>/dev/null || true
        docker cp almeyo-backend:/app/logs "$BACKUP_DIR/logs_$TIMESTAMP" 2>/dev/null || true
        log_info "Backup completed: $BACKUP_DIR/data_$TIMESTAMP"
    else
        log_warn "No existing Almeyo instance found. Skipping backup."
    fi
}

# Build images
build_images() {
    log_info "Building Docker images..."
    docker compose -f "$DOCKER_COMPOSE_FILE" build --no-cache
    log_info "Images built successfully."
}

# Pull images if using pre-built (optional)
pull_images() {
    log_info "Pulling images..."
    docker compose -f "$DOCKER_COMPOSE_FILE" pull || true
}

# Start services
start_services() {
    log_info "Starting Almeyo services..."
    docker compose -f "$DOCKER_COMPOSE_FILE" up -d
    log_info "Services started."
}

# Wait for services to be healthy
wait_for_health() {
    log_info "Waiting for services to be healthy..."
    
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker ps | grep -q "almeyo-backend.*healthy" && \
           docker ps | grep -q "almeyo-frontend.*healthy" && \
           docker ps | grep -q "almeyo-nginx.*healthy"; then
            log_info "All services are healthy."
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 1
    done
    
    log_warn "Services did not reach healthy state within timeout."
    log_info "Checking service status..."
    docker compose -f "$DOCKER_COMPOSE_FILE" ps
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check if services are running
    if ! docker compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "almeyo-backend"; then
        log_error "Backend service is not running."
        return 1
    fi
    
    if ! docker compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "almeyo-frontend"; then
        log_error "Frontend service is not running."
        return 1
    fi
    
    if ! docker compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "almeyo-nginx"; then
        log_error "Nginx service is not running."
        return 1
    fi
    
    # Test API endpoint
    log_info "Testing API endpoint..."
    if curl -f http://localhost/api/health > /dev/null 2>&1; then
        log_info "API health check passed."
    else
        log_warn "API health check failed. Check logs with: docker compose -f $DOCKER_COMPOSE_FILE logs backend"
    fi
    
    # Test frontend
    log_info "Testing frontend..."
    if curl -f http://localhost/ > /dev/null 2>&1; then
        log_info "Frontend is responding."
    else
        log_warn "Frontend is not responding. Check logs with: docker compose -f $DOCKER_COMPOSE_FILE logs frontend"
    fi
    
    log_info "Deployment verification complete."
}

# Show logs
show_logs() {
    log_info "Showing recent logs..."
    docker compose -f "$DOCKER_COMPOSE_FILE" logs --tail=50 -f
}

# Stop services
stop_services() {
    log_info "Stopping services..."
    docker compose -f "$DOCKER_COMPOSE_FILE" down
    log_info "Services stopped."
}

# Main deployment
main() {
    log_info "Starting Almeyo production deployment..."
    echo ""
    
    check_prerequisites
    backup_data
    build_images
    start_services
    wait_for_health
    verify_deployment
    
    echo ""
    log_info "Deployment completed successfully!"
    echo ""
    echo "Almeyo is now running:"
    echo "  - Frontend: http://localhost"
    echo "  - API: http://localhost/api"
    echo ""
    echo "To view logs: docker compose -f $DOCKER_COMPOSE_FILE logs -f"
    echo "To stop: docker compose -f $DOCKER_COMPOSE_FILE down"
}

# Handle command line arguments
case "${1:-deploy}" in
    deploy)
        main
        ;;
    logs)
        show_logs
        ;;
    stop)
        stop_services
        ;;
    restart)
        stop_services
        main
        ;;
    verify)
        verify_deployment
        ;;
    *)
        echo "Usage: $0 {deploy|logs|stop|restart|verify}"
        exit 1
        ;;
esac
