#!/bin/bash

# Simple EnglishKaku API Deployment Script
# Deploys the API directly on a port without nginx

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}EnglishKaku API Simple Deployment${NC}"
echo "=================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root for security reasons${NC}"
   echo "Please run as a regular user with sudo privileges"
   exit 1
fi

# Get port from user
read -p "Enter port number (default: 5000): " PORT
PORT=${PORT:-5000}

# Validate port
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1024 ] || [ "$PORT" -gt 65535 ]; then
    echo -e "${RED}Invalid port number. Please enter a port between 1024-65535${NC}"
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

# Create project directory
PROJECT_DIR="/home/$USER/englishkaku-api"
echo -e "${BLUE}Setting up project directory: $PROJECT_DIR${NC}"

if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# Copy project files (assuming we're running from the project directory)
echo -e "${BLUE}Copying project files...${NC}"
echo -e "${YELLOW}Please ensure these files are in $PROJECT_DIR:${NC}"
echo "  - app.py"
echo "  - requirements.txt"
echo "  - Dockerfile"
echo "  - docker-compose.simple.yml"

# Update docker-compose file with custom port
if [ -f "docker-compose.simple.yml" ]; then
    sed -i "s/\"5000:5000\"/\"$PORT:5000\"/g" docker-compose.simple.yml
    echo -e "${GREEN}Updated docker-compose.simple.yml with port $PORT${NC}"
fi

# Build and start the application
echo -e "${BLUE}Building and starting the application...${NC}"
docker-compose -f docker-compose.simple.yml down --remove-orphans 2>/dev/null || true
docker-compose -f docker-compose.simple.yml build --no-cache
docker-compose -f docker-compose.simple.yml up -d

# Wait for services to start
echo -e "${BLUE}Waiting for services to start...${NC}"
sleep 30

# Check if services are running
if docker-compose -f docker-compose.simple.yml ps | grep -q "Up"; then
    echo -e "${GREEN}Application deployed successfully!${NC}"
    echo -e "${GREEN}API is running at: http://$(hostname -I | awk '{print $1}'):$PORT${NC}"
    echo -e "${GREEN}Health check: http://$(hostname -I | awk '{print $1}'):$PORT/health${NC}"
else
    echo -e "${RED}Deployment failed. Check logs with: docker-compose -f docker-compose.simple.yml logs${NC}"
    exit 1
fi

# Create management scripts
echo -e "${BLUE}Creating management scripts...${NC}"

# Start script
cat > start.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
docker-compose -f docker-compose.simple.yml up -d
echo "Application started on port $PORT!"
EOF

# Stop script
cat > stop.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
docker-compose -f docker-compose.simple.yml down
echo "Application stopped!"
EOF

# Restart script
cat > restart.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
docker-compose -f docker-compose.simple.yml restart
echo "Application restarted on port $PORT!"
EOF

# Logs script
cat > logs.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
docker-compose -f docker-compose.simple.yml logs -f
EOF

# Update script
cat > update.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
docker-compose -f docker-compose.simple.yml down
docker-compose -f docker-compose.simple.yml build --no-cache
docker-compose -f docker-compose.simple.yml up -d
echo "Application updated on port $PORT!"
EOF

# Status script
cat > status.sh << EOF
#!/bin/bash
cd $PROJECT_DIR
echo "EnglishKaku API Status:"
docker-compose -f docker-compose.simple.yml ps
echo ""
echo "API Endpoints:"
echo "  Main API: http://$(hostname -I | awk '{print $1}'):$PORT"
echo "  Health:   http://$(hostname -I | awk '{print $1}'):$PORT/health"
echo "  Docs:     http://$(hostname -I | awk '{print $1}'):$PORT/"
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
echo "  ./status.sh   - Check application status"
echo ""
echo -e "${BLUE}Your API is now available at:${NC}"
echo -e "${GREEN}  http://$(hostname -I | awk '{print $1}'):$PORT${NC}"
echo -e "${GREEN}  http://$(hostname -I | awk '{print $1}'):$PORT/health${NC}"
echo ""
echo -e "${YELLOW}Note: Make sure port $PORT is open in your firewall${NC}"
echo -e "${YELLOW}For Ubuntu/Debian: sudo ufw allow $PORT${NC}"
echo -e "${YELLOW}For CentOS/RHEL: sudo firewall-cmd --permanent --add-port=$PORT/tcp && sudo firewall-cmd --reload${NC}"
