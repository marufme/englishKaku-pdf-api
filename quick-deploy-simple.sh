#!/bin/bash

# Quick simple deployment script for EnglishKaku API
# Deploys directly on a port without nginx

set -e

echo "🚀 EnglishKaku API Simple Deploy"
echo "================================"

# Check if we're in the right directory
if [ ! -f "app.py" ] || [ ! -f "requirements.txt" ] || [ ! -f "Dockerfile" ]; then
    echo "❌ Error: Please run this script from the project directory"
    echo "Required files: app.py, requirements.txt, Dockerfile"
    exit 1
fi

# Set port number to 5000 for automated deployment
PORT=5000
echo "🌐 Using port: $PORT"

echo "📦 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

echo "📦 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

echo "🔧 Creating docker-compose configuration..."
cat > docker-compose.simple.yml << EOF
version: "3.8"

services:
  api:
    build: .
    ports:
      - "$PORT:5000"
    environment:
      - FLASK_ENV=production
      - FLASK_DEBUG=0
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

echo "🏗️ Building and starting application..."
docker-compose -f docker-compose.simple.yml down --remove-orphans 2>/dev/null || true
docker-compose -f docker-compose.simple.yml build --no-cache
docker-compose -f docker-compose.simple.yml up -d

echo "⏳ Waiting for services to start..."
sleep 30

# Check if services are running
if docker-compose -f docker-compose.simple.yml ps | grep -q "Up"; then
    echo "✅ Application deployed successfully!"
    echo ""
    echo "🌐 Your API is now available at:"
    echo "   http://$(hostname -I | awk '{print $1}'):$PORT"
    echo "   http://$(hostname -I | awk '{print $1}'):$PORT/health"
    echo ""
    echo "📋 Management commands:"
    echo "   Start:   docker-compose -f docker-compose.simple.yml up -d"
    echo "   Stop:    docker-compose -f docker-compose.simple.yml down"
    echo "   Logs:    docker-compose -f docker-compose.simple.yml logs -f"
    echo "   Restart: docker-compose -f docker-compose.simple.yml restart"
    echo ""
    echo "🔒 Don't forget to open port $PORT in your firewall:"
    echo "   Ubuntu/Debian: sudo ufw allow $PORT"
    echo "   CentOS/RHEL:   sudo firewall-cmd --permanent --add-port=$PORT/tcp && sudo firewall-cmd --reload"
else
    echo "❌ Deployment failed. Check logs:"
    echo "   docker-compose -f docker-compose.simple.yml logs"
    exit 1
fi
