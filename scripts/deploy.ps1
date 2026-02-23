@echo off
REM Almeyo Production Deployment Script for Windows
REM This script builds and deploys Almeyo with Docker Compose

setlocal enabledelayedexpansion

REM Configuration
set ENV_FILE=.env.prod
set DOCKER_COMPOSE_FILE=docker-compose.prod.yml
set BACKUP_DIR=.\backups
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set TIMESTAMP=%mydate%_%mytime%

REM Check prerequisites
echo [INFO] Checking prerequisites...

where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker is not installed. Please install Docker.
    exit /b 1
)

where docker-compose >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    where docker >nul 2>nul
    docker compose --version >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Docker Compose is not installed. Please install Docker Compose.
        exit /b 1
    )
)

if not exist "%ENV_FILE%" (
    echo [ERROR] .env.prod file not found. Please create it from .env.prod.example
    exit /b 1
)

echo [INFO] All prerequisites checked.
echo.

REM Backup existing data
echo [INFO] Backing up existing data...
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

docker ps -aq -f "name=almeyo-backend" >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Backing up database and logs...
    docker cp almeyo-backend:/app/data "%BACKUP_DIR%\data_%TIMESTAMP%" >nul 2>nul
    docker cp almeyo-backend:/app/logs "%BACKUP_DIR%\logs_%TIMESTAMP%" >nul 2>nul
    echo [INFO] Backup completed: %BACKUP_DIR%\data_%TIMESTAMP%
) else (
    echo [WARN] No existing Almeyo instance found. Skipping backup.
)
echo.

REM Build images
echo [INFO] Building Docker images...
docker compose -f "%DOCKER_COMPOSE_FILE%" build --no-cache
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to build images.
    exit /b 1
)
echo [INFO] Images built successfully.
echo.

REM Start services
echo [INFO] Starting Almeyo services...
docker compose -f "%DOCKER_COMPOSE_FILE%" up -d
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to start services.
    exit /b 1
)
echo [INFO] Services started.
echo.

REM Wait for services
echo [INFO] Waiting for services to be healthy...
timeout /t 5 /nobreak
echo.

REM Verify deployment
echo [INFO] Verifying deployment...
docker compose -f "%DOCKER_COMPOSE_FILE%" ps
echo.

REM Show status
echo [INFO] Deployment completed!
echo.
echo Almeyo is now running:
echo   - Frontend: http://localhost
echo   - API: http://localhost/api
echo.
echo To view logs: docker compose -f %DOCKER_COMPOSE_FILE% logs -f
echo To stop: docker compose -f %DOCKER_COMPOSE_FILE% down
echo.
