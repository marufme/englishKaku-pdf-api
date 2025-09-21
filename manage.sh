#!/bin/bash

# EnglishKaku API Management Script
# Provides easy commands to manage your deployed API

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.prod.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if docker-compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: docker-compose.prod.yml not found in $PROJECT_DIR${NC}"
    exit 1
fi

# Function to show usage
show_usage() {
    echo -e "${BLUE}EnglishKaku API Management Script${NC}"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Start the API"
    echo "  stop      - Stop the API"
    echo "  restart   - Restart the API"
    echo "  status    - Show status of services"
    echo "  logs      - Show logs (use -f for follow)"
    echo "  update    - Update and restart the API"
    echo "  health    - Check API health"
    echo "  ssl       - Setup Let's Encrypt SSL"
    echo "  backup    - Backup configuration"
    echo "  restore   - Restore from backup"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs -f"
    echo "  $0 ssl yourdomain.com your@email.com"
}

# Function to start services
start_services() {
    echo -e "${BLUE}Starting EnglishKaku API...${NC}"
    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.prod.yml up -d
    echo -e "${GREEN}API started successfully!${NC}"
}

# Function to stop services
stop_services() {
    echo -e "${BLUE}Stopping EnglishKaku API...${NC}"
    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.prod.yml down
    echo -e "${GREEN}API stopped successfully!${NC}"
}

# Function to restart services
restart_services() {
    echo -e "${BLUE}Restarting EnglishKaku API...${NC}"
    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.prod.yml restart
    echo -e "${GREEN}API restarted successfully!${NC}"
}

# Function to show status
show_status() {
    echo -e "${BLUE}EnglishKaku API Status${NC}"
    echo "====================="
    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.prod.yml ps
}

# Function to show logs
show_logs() {
    cd "$PROJECT_DIR"
    if [ "$1" = "-f" ]; then
        echo -e "${BLUE}Showing logs (following)...${NC}"
        docker-compose -f docker-compose.prod.yml logs -f
    else
        echo -e "${BLUE}Showing recent logs...${NC}"
        docker-compose -f docker-compose.prod.yml logs --tail=50
    fi
}

# Function to update services
update_services() {
    echo -e "${BLUE}Updating EnglishKaku API...${NC}"
    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.prod.yml down
    docker-compose -f docker-compose.prod.yml build --no-cache
    docker-compose -f docker-compose.prod.yml up -d
    echo -e "${GREEN}API updated successfully!${NC}"
}

# Function to check health
check_health() {
    echo -e "${BLUE}Checking API health...${NC}"
    
    # Try to get the domain from nginx config
    DOMAIN=$(grep "server_name" "$PROJECT_DIR/nginx.conf" | head -1 | awk '{print $2}' | sed 's/;//')
    
    if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "_" ]; then
        echo "Testing: https://$DOMAIN/health"
        curl -s -f "https://$DOMAIN/health" && echo -e "${GREEN}API is healthy!${NC}" || echo -e "${RED}API health check failed!${NC}"
    else
        echo "Testing: http://localhost:5000/health"
        curl -s -f "http://localhost:5000/health" && echo -e "${GREEN}API is healthy!${NC}" || echo -e "${RED}API health check failed!${NC}"
    fi
}

# Function to setup SSL
setup_ssl() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Usage: $0 ssl <domain> <email>${NC}"
        exit 1
    fi
    
    DOMAIN="$1"
    EMAIL="$2"
    
    echo -e "${BLUE}Setting up Let's Encrypt SSL for $DOMAIN...${NC}"
    
    # Install certbot if not present
    if ! command -v certbot &> /dev/null; then
        echo "Installing certbot..."
        sudo apt update
        sudo apt install -y certbot
    fi
    
    # Stop nginx temporarily
    echo "Stopping nginx..."
    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.prod.yml stop nginx
    
    # Get certificate
    echo "Getting SSL certificate..."
    sudo certbot certonly --standalone -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
    
    # Copy certificates
    echo "Installing certificates..."
    sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$PROJECT_DIR/ssl/cert.pem"
    sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$PROJECT_DIR/ssl/key.pem"
    sudo chown $USER:$USER "$PROJECT_DIR/ssl/cert.pem" "$PROJECT_DIR/ssl/key.pem"
    
    # Update nginx config with domain
    sed -i "s/server_name _;/server_name $DOMAIN;/g" "$PROJECT_DIR/nginx.conf"
    
    # Restart nginx
    echo "Starting nginx..."
    docker-compose -f docker-compose.prod.yml up -d nginx
    
    echo -e "${GREEN}SSL certificate installed successfully!${NC}"
    echo -e "${GREEN}Your API is now available at: https://$DOMAIN${NC}"
}

# Function to backup configuration
backup_config() {
    echo -e "${BLUE}Creating backup...${NC}"
    BACKUP_FILE="englishkaku-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    cd "$PROJECT_DIR"
    tar -czf "$BACKUP_FILE" \
        docker-compose.prod.yml \
        nginx.conf \
        ssl/ \
        app.py \
        requirements.txt \
        Dockerfile*
    
    echo -e "${GREEN}Backup created: $BACKUP_FILE${NC}"
}

# Function to restore from backup
restore_config() {
    if [ -z "$1" ]; then
        echo -e "${RED}Usage: $0 restore <backup-file>${NC}"
        echo "Available backups:"
        ls -la *.tar.gz 2>/dev/null || echo "No backup files found"
        exit 1
    fi
    
    BACKUP_FILE="$1"
    
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}Backup file not found: $BACKUP_FILE${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Restoring from backup: $BACKUP_FILE${NC}"
    
    # Stop services
    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.prod.yml down
    
    # Extract backup
    tar -xzf "$BACKUP_FILE"
    
    # Start services
    docker-compose -f docker-compose.prod.yml up -d
    
    echo -e "${GREEN}Restore completed successfully!${NC}"
}

# Main script logic
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    update)
        update_services
        ;;
    health)
        check_health
        ;;
    ssl)
        setup_ssl "$2" "$3"
        ;;
    backup)
        backup_config
        ;;
    restore)
        restore_config "$2"
        ;;
    *)
        show_usage
        ;;
esac
