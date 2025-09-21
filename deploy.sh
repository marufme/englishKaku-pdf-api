#!/bin/bash

# EnglishKaku API Deployment Script for VPS
# This script sets up the API on a VPS with Docker, Nginx, and SSL

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN=""
EMAIL=""
API_PORT=5000

echo -e "${BLUE}EnglishKaku API VPS Deployment Script${NC}"
echo "=================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root for security reasons${NC}"
   echo "Please run as a regular user with sudo privileges"
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker is not installed. Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}Docker installed successfully!${NC}"
    echo -e "${YELLOW}Please log out and log back in for Docker group changes to take effect${NC}"
    exit 0
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Docker Compose is not installed. Installing...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose installed successfully!${NC}"
fi

# Get domain and email from user
if [ -z "$DOMAIN" ]; then
    read -p "Enter your domain name (e.g., api.yourdomain.com): " DOMAIN
fi

if [ -z "$EMAIL" ]; then
    read -p "Enter your email address for SSL certificate: " EMAIL
fi

# Create project directory
PROJECT_DIR="/home/$USER/englishkaku-api"
echo -e "${BLUE}Setting up project directory: $PROJECT_DIR${NC}"

if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# Copy project files (assuming we're running from the project directory)
echo -e "${BLUE}Copying project files...${NC}"
cp -r /path/to/your/project/* "$PROJECT_DIR/" 2>/dev/null || {
    echo -e "${YELLOW}Please copy your project files to $PROJECT_DIR manually${NC}"
    echo "Required files: app.py, requirements.txt, Dockerfile, docker-compose.prod.yml, nginx.conf"
}

# Create SSL directory
mkdir -p ssl

# Generate self-signed certificate for initial setup
echo -e "${BLUE}Generating self-signed SSL certificate...${NC}"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/key.pem \
    -out ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"

# Update nginx.conf with domain
sed -i "s/server_name _;/server_name $DOMAIN;/g" nginx.conf

# Build and start the application
echo -e "${BLUE}Building and starting the application...${NC}"
docker-compose -f docker-compose.prod.yml down --remove-orphans
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to start
echo -e "${BLUE}Waiting for services to start...${NC}"
sleep 30

# Check if services are running
if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo -e "${GREEN}Application deployed successfully!${NC}"
    echo -e "${GREEN}API is running at: https://$DOMAIN${NC}"
    echo -e "${GREEN}Health check: https://$DOMAIN/health${NC}"
else
    echo -e "${RED}Deployment failed. Check logs with: docker-compose -f docker-compose.prod.yml logs${NC}"
    exit 1
fi

# Setup Let's Encrypt SSL (optional)
echo -e "${YELLOW}Would you like to setup Let's Encrypt SSL certificate? (y/n)${NC}"
read -p "> " setup_ssl

if [[ $setup_ssl == "y" || $setup_ssl == "Y" ]]; then
    echo -e "${BLUE}Setting up Let's Encrypt SSL...${NC}"
    
    # Install certbot
    sudo apt update
    sudo apt install -y certbot
    
    # Stop nginx temporarily
    docker-compose -f docker-compose.prod.yml stop nginx
    
    # Get certificate
    sudo certbot certonly --standalone -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
    
    # Copy certificates
    sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ssl/cert.pem
    sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ssl/key.pem
    sudo chown $USER:$USER ssl/cert.pem ssl/key.pem
    
    # Restart nginx
    docker-compose -f docker-compose.prod.yml up -d nginx
    
    echo -e "${GREEN}Let's Encrypt SSL certificate installed successfully!${NC}"
fi

# Setup auto-renewal for Let's Encrypt
if [[ $setup_ssl == "y" || $setup_ssl == "Y" ]]; then
    echo -e "${BLUE}Setting up SSL certificate auto-renewal...${NC}"
    
    # Create renewal script
    cat > renew_ssl.sh << EOF
#!/bin/bash
certbot renew --quiet
if [ \$? -eq 0 ]; then
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $PROJECT_DIR/ssl/cert.pem
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $PROJECT_DIR/ssl/key.pem
    chown $USER:$USER $PROJECT_DIR/ssl/cert.pem $PROJECT_DIR/ssl/key.pem
    docker-compose -f $PROJECT_DIR/docker-compose.prod.yml restart nginx
fi
EOF
    
    chmod +x renew_ssl.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * $PROJECT_DIR/renew_ssl.sh") | crontab -
    
    echo -e "${GREEN}SSL auto-renewal configured!${NC}"
fi

# Create management scripts
echo -e "${BLUE}Creating management scripts...${NC}"

# Start script
cat > start.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
docker-compose -f docker-compose.prod.yml up -d
echo "Application started!"
EOF

# Stop script
cat > stop.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
docker-compose -f docker-compose.prod.yml down
echo "Application stopped!"
EOF

# Restart script
cat > restart.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
docker-compose -f docker-compose.prod.yml restart
echo "Application restarted!"
EOF

# Logs script
cat > logs.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
docker-compose -f docker-compose.prod.yml logs -f
EOF

# Update script
cat > update.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
echo "Application updated!"
EOF

chmod +x *.sh

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo "  ./start.sh    - Start the application"
echo "  ./stop.sh     - Stop the application"
echo "  ./restart.sh  - Restart the application"
echo "  ./logs.sh     - View application logs"
echo "  ./update.sh   - Update and restart the application"
echo ""
echo -e "${BLUE}Your API is now available at: https://$DOMAIN${NC}"
echo -e "${BLUE}Health check: https://$DOMAIN/health${NC}"
echo ""
echo -e "${YELLOW}Note: Make sure to configure your domain's DNS to point to this server's IP address${NC}"
