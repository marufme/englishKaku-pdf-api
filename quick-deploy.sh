#!/bin/bash

# Quick deployment script for EnglishKaku API
# Run this script on your VPS to deploy the API

set -e

echo "🚀 EnglishKaku API Quick Deploy"
echo "================================"

# Check if we're in the right directory
if [ ! -f "app.py" ] || [ ! -f "requirements.txt" ] || [ ! -f "Dockerfile" ]; then
    echo "❌ Error: Please run this script from the project directory"
    echo "Required files: app.py, requirements.txt, Dockerfile"
    exit 1
fi

# Get domain name
read -p "🌐 Enter your domain name (e.g., api.yourdomain.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ Domain name is required"
    exit 1
fi

# Get email for SSL
read -p "📧 Enter your email for SSL certificate: " EMAIL

if [ -z "$EMAIL" ]; then
    echo "❌ Email is required for SSL certificate"
    exit 1
fi

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

echo "🔧 Setting up SSL certificates..."
mkdir -p ssl

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/key.pem \
    -out ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"

echo "🔧 Updating nginx configuration..."
if [ -f "nginx.conf" ]; then
    sed -i "s/server_name _;/server_name $DOMAIN;/g" nginx.conf
fi

echo "🏗️ Building and starting application..."
docker-compose -f docker-compose.prod.yml down --remove-orphans 2>/dev/null || true
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

echo "⏳ Waiting for services to start..."
sleep 30

# Check if services are running
if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo "✅ Application deployed successfully!"
    echo ""
    echo "🌐 Your API is now available at:"
    echo "   https://$DOMAIN"
    echo "   https://$DOMAIN/health"
    echo ""
    echo "📋 Management commands:"
    echo "   Start:   docker-compose -f docker-compose.prod.yml up -d"
    echo "   Stop:    docker-compose -f docker-compose.prod.yml down"
    echo "   Logs:    docker-compose -f docker-compose.prod.yml logs -f"
    echo "   Restart: docker-compose -f docker-compose.prod.yml restart"
    echo ""
    echo "🔒 To setup Let's Encrypt SSL:"
    echo "   1. sudo apt install certbot"
    echo "   2. docker-compose -f docker-compose.prod.yml stop nginx"
    echo "   3. sudo certbot certonly --standalone -d $DOMAIN --email $EMAIL --agree-tos"
    echo "   4. sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/cert.pem"
    echo "   5. sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/key.pem"
    echo "   6. sudo chown $USER:$USER ssl/cert.pem ssl/key.pem"
    echo "   7. docker-compose -f docker-compose.prod.yml up -d nginx"
else
    echo "❌ Deployment failed. Check logs:"
    echo "   docker-compose -f docker-compose.prod.yml logs"
    exit 1
fi
