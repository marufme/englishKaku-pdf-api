# EnglishKaku API - VPS Deployment Guide

This guide will help you deploy your EnglishKaku PDF API to a VPS using Docker, Nginx, and SSL.

## Prerequisites

- A VPS with Ubuntu 20.04+ or similar Linux distribution
- A domain name pointing to your VPS IP address
- SSH access to your VPS
- Basic knowledge of Linux commands

## Quick Deployment

### 1. Upload Files to VPS

Upload these files to your VPS:
- `app.py`
- `requirements.txt`
- `Dockerfile`
- `docker-compose.prod.yml`
- `nginx.conf`
- `deploy.sh`

### 2. Run Deployment Script

```bash
# Make the script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

The script will:
- Install Docker and Docker Compose if not present
- Set up SSL certificates
- Configure Nginx as reverse proxy
- Deploy your API with Docker
- Create management scripts

### 3. Access Your API

Your API will be available at:
- **HTTPS**: `https://yourdomain.com`
- **Health Check**: `https://yourdomain.com/health`

## Manual Deployment Steps

If you prefer to deploy manually:

### 1. Install Docker

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Log out and log back in
exit
```

### 2. Setup Project Directory

```bash
# Create project directory
mkdir -p ~/englishkaku-api
cd ~/englishkaku-api

# Copy your project files here
# Upload: app.py, requirements.txt, Dockerfile, docker-compose.prod.yml, nginx.conf
```

### 3. Generate SSL Certificate

```bash
# Create SSL directory
mkdir -p ssl

# Generate self-signed certificate (replace with your domain)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/key.pem \
    -out ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=yourdomain.com"
```

### 4. Deploy Application

```bash
# Build and start
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps
```

## Let's Encrypt SSL Setup

For production, use Let's Encrypt for free SSL certificates:

### 1. Install Certbot

```bash
sudo apt install -y certbot
```

### 2. Get Certificate

```bash
# Stop nginx temporarily
docker-compose -f docker-compose.prod.yml stop nginx

# Get certificate
sudo certbot certonly --standalone -d yourdomain.com --email your@email.com --agree-tos

# Copy certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/key.pem
sudo chown $USER:$USER ssl/cert.pem ssl/key.pem

# Restart nginx
docker-compose -f docker-compose.prod.yml up -d nginx
```

### 3. Auto-renewal Setup

```bash
# Create renewal script
cat > renew_ssl.sh << 'EOF'
#!/bin/bash
certbot renew --quiet
if [ $? -eq 0 ]; then
    cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ~/englishkaku-api/ssl/cert.pem
    cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ~/englishkaku-api/ssl/key.pem
    chown $USER:$USER ~/englishkaku-api/ssl/cert.pem ~/englishkaku-api/ssl/key.pem
    docker-compose -f ~/englishkaku-api/docker-compose.prod.yml restart nginx
fi
EOF

chmod +x renew_ssl.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * ~/englishkaku-api/renew_ssl.sh") | crontab -
```

## Management Commands

After deployment, you can use these commands:

```bash
# Start application
docker-compose -f docker-compose.prod.yml up -d

# Stop application
docker-compose -f docker-compose.prod.yml down

# Restart application
docker-compose -f docker-compose.prod.yml restart

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Update application
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

## API Usage

### Endpoints

- **POST** `/convert-to-pdf` - Convert JSON to PDF
- **GET** `/health` - Health check
- **GET** `/` - API documentation

### Example Request

```bash
curl -X POST https://yourdomain.com/convert-to-pdf \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Sample News",
    "time": "2025-01-01T12:00:00Z",
    "message": {
      "content": "This is sample content for testing.",
      "sentence": "[{\"word\":\"sample\",\"meaning_bn\":\"নমুনা\",\"example_en\":\"This is a sample.\",\"example_bn\":\"এটি একটি নমুনা।\"}]"
    },
    "output": [
      {
        "english": "sample",
        "bengali": "নমুনা",
        "synonyms": ["example", "specimen"],
        "antonyms": ["original", "real"]
      }
    ]
  }' \
  --output sample.pdf
```

## Troubleshooting

### Check Container Status

```bash
docker-compose -f docker-compose.prod.yml ps
```

### View Logs

```bash
# All services
docker-compose -f docker-compose.prod.yml logs

# Specific service
docker-compose -f docker-compose.prod.yml logs api
docker-compose -f docker-compose.prod.yml logs nginx
```

### Test API Locally

```bash
# Test health endpoint
curl http://localhost:5000/health

# Test PDF generation
curl -X POST http://localhost:5000/convert-to-pdf \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "output": [{"english": "test", "bengali": "পরীক্ষা", "synonyms": [], "antonyms": []}]}'
```

### Common Issues

1. **Port 80/443 already in use**: Stop other web servers
2. **SSL certificate errors**: Check domain DNS settings
3. **PDF generation fails**: Check WeasyPrint dependencies
4. **Permission denied**: Ensure user is in docker group

## Security Considerations

- The deployment includes security headers
- Rate limiting is configured (10 requests/second)
- SSL/TLS encryption is enforced
- Regular security updates recommended

## Monitoring

### Health Check

```bash
curl https://yourdomain.com/health
```

### Resource Usage

```bash
# Docker stats
docker stats

# System resources
htop
```

## Backup

### Backup Application Data

```bash
# Backup SSL certificates
tar -czf ssl-backup.tar.gz ssl/

# Backup configuration
tar -czf config-backup.tar.gz docker-compose.prod.yml nginx.conf
```

## Updates

To update your application:

1. Upload new code files
2. Run: `docker-compose -f docker-compose.prod.yml down`
3. Run: `docker-compose -f docker-compose.prod.yml build --no-cache`
4. Run: `docker-compose -f docker-compose.prod.yml up -d`

## Support

For issues or questions:
1. Check logs: `docker-compose -f docker-compose.prod.yml logs`
2. Verify configuration files
3. Test API endpoints individually
4. Check VPS resources and network connectivity
