# EnglishKaku API - Simple VPS Deployment Guide

This guide will help you deploy your EnglishKaku PDF API to a VPS using Docker on a specific port (no nginx required).

## Prerequisites

- A VPS with Ubuntu 20.04+ or similar Linux distribution
- SSH access to your VPS
- Basic knowledge of Linux commands

## Quick Deployment

### 1. Upload Files to VPS

Upload these files to your VPS:

- `app.py`
- `requirements.txt`
- `Dockerfile`
- `docker-compose.simple.yml`
- `deploy-simple.sh`

### 2. Run Deployment Script

```bash
# Make the script executable
chmod +x deploy-simple.sh

# Run the deployment script
./deploy-simple.sh
```

The script will:

- Install Docker and Docker Compose if not present
- Ask for a port number (default: 5000)
- Deploy your API with Docker
- Create management scripts

### 3. Access Your API

Your API will be available at:

- **HTTP**: `http://your-vps-ip:port`
- **Health Check**: `http://your-vps-ip:port/health`

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
# Upload: app.py, requirements.txt, Dockerfile, docker-compose.simple.yml
```

### 3. Configure Port

Edit `docker-compose.simple.yml` to change the port:

```yaml
version: "3.8"

services:
  api:
    build: .
    ports:
      - "YOUR_PORT:5000" # Change YOUR_PORT to desired port
    environment:
      - FLASK_ENV=production
      - FLASK_DEBUG=0
    restart: unless-stopped
```

### 4. Deploy Application

```bash
# Build and start
docker-compose -f docker-compose.simple.yml up -d

# Check status
docker-compose -f docker-compose.simple.yml ps
```

### 5. Open Firewall Port

```bash
# Ubuntu/Debian
sudo ufw allow YOUR_PORT

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=YOUR_PORT/tcp
sudo firewall-cmd --reload
```

## Management Commands

After deployment, you can use these commands:

```bash
# Start application
docker-compose -f docker-compose.simple.yml up -d

# Stop application
docker-compose -f docker-compose.simple.yml down

# Restart application
docker-compose -f docker-compose.simple.yml restart

# View logs
docker-compose -f docker-compose.simple.yml logs -f

# Update application
docker-compose -f docker-compose.simple.yml down
docker-compose -f docker-compose.simple.yml build --no-cache
docker-compose -f docker-compose.simple.yml up -d
```

## API Usage

### Endpoints

- **POST** `/convert-to-pdf` - Convert JSON to PDF
- **GET** `/health` - Health check
- **GET** `/` - API documentation

### Example Request

```bash
curl -X POST http://your-vps-ip:port/convert-to-pdf \
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
docker-compose -f docker-compose.simple.yml ps
```

### View Logs

```bash
# All services
docker-compose -f docker-compose.simple.yml logs

# Follow logs
docker-compose -f docker-compose.simple.yml logs -f
```

### Test API Locally

```bash
# Test health endpoint
curl http://localhost:YOUR_PORT/health

# Test PDF generation
curl -X POST http://localhost:YOUR_PORT/convert-to-pdf \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "output": [{"english": "test", "bengali": "পরীক্ষা", "synonyms": [], "antonyms": []}]}'
```

### Common Issues

1. **Port already in use**: Choose a different port
2. **Permission denied**: Ensure user is in docker group
3. **PDF generation fails**: Check WeasyPrint dependencies
4. **Connection refused**: Check firewall settings

## Security Considerations

- The API runs in production mode (no debug)
- Consider using a reverse proxy (nginx) for production
- Implement rate limiting if needed
- Use HTTPS with a reverse proxy for secure connections

## Monitoring

### Health Check

```bash
curl http://your-vps-ip:port/health
```

### Resource Usage

```bash
# Docker stats
docker stats

# System resources
htop
```

## Updates

To update your application:

1. Upload new code files
2. Run: `docker-compose -f docker-compose.simple.yml down`
3. Run: `docker-compose -f docker-compose.simple.yml build --no-cache`
4. Run: `docker-compose -f docker-compose.simple.yml up -d`

## Port Configuration

### Default Ports

- **5000**: Default Flask port
- **8080**: Alternative common port
- **3000**: Another alternative

### Custom Ports

You can use any port between 1024-65535. Common choices:

- 8000, 8001, 8002
- 9000, 9001, 9002
- 3000, 3001, 3002

### Firewall Commands by OS

**Ubuntu/Debian:**

```bash
sudo ufw allow PORT_NUMBER
sudo ufw status
```

**CentOS/RHEL:**

```bash
sudo firewall-cmd --permanent --add-port=PORT_NUMBER/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
```

**Amazon Linux:**

```bash
sudo iptables -A INPUT -p tcp --dport PORT_NUMBER -j ACCEPT
sudo service iptables save
```

## Support

For issues or questions:

1. Check logs: `docker-compose -f docker-compose.simple.yml logs`
2. Verify port is open: `netstat -tlnp | grep PORT_NUMBER`
3. Test API endpoints individually
4. Check VPS resources and network connectivity
