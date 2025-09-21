@echo off
echo Building and starting English-Bengali Dictionary API with Docker...
echo.

echo Building Docker image...
docker-compose build

echo.
echo Starting the API...
docker-compose up

echo.
echo API is running at http://localhost:5000
echo Press Ctrl+C to stop the API
pause
