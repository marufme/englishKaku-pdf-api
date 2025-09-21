Write-Host "Building and starting English-Bengali Dictionary API with Docker..." -ForegroundColor Green
Write-Host ""

Write-Host "Building Docker image..." -ForegroundColor Yellow
docker-compose build

Write-Host ""
Write-Host "Starting the API..." -ForegroundColor Yellow
docker-compose up

Write-Host ""
Write-Host "API is running at http://localhost:5000" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the API" -ForegroundColor Cyan
