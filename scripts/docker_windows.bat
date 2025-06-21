@echo off
title Cursor To OpenAI - Docker Builder

REM Cursor To OpenAI - Docker Build Script for Windows
echo =========================================
echo   Cursor To OpenAI Docker Builder       
echo =========================================

REM Configuration
set IMAGE_NAME=cursor-to-openai
set IMAGE_TAG=latest
set CONTAINER_NAME=cursor-to-openai-container
set PORT=3010
set REGISTRY_USER=

REM Get command line argument
set COMMAND=%1
if "%COMMAND%"=="" set COMMAND=help

REM Main script logic
if /i "%COMMAND%"=="build" goto build
if /i "%COMMAND%"=="run" goto run
if /i "%COMMAND%"=="stop" goto stop
if /i "%COMMAND%"=="restart" goto restart
if /i "%COMMAND%"=="logs" goto logs
if /i "%COMMAND%"=="status" goto status
if /i "%COMMAND%"=="push" goto push
if /i "%COMMAND%"=="cleanup" goto cleanup
if /i "%COMMAND%"=="help" goto help
goto help

:check_docker
echo ℹ️  Checking Docker installation...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed or not in PATH
    echo    Please install Docker Desktop from https://docs.docker.com/desktop/windows/
    pause
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker daemon is not running
    echo    Please start Docker Desktop
    pause
    exit /b 1
)

echo ✅ Docker is available
goto :eof

:create_dockerignore
if not exist ".dockerignore" (
    echo ℹ️  Creating .dockerignore file
    (
        echo node_modules
        echo npm-debug.log
        echo .git
        echo .gitignore
        echo README.md
        echo .env
        echo .nyc_output
        echo coverage
        echo .DS_Store
        echo logs
        echo *.log
        echo .vscode
        echo scripts
    ) > .dockerignore
)
goto :eof

:build
call :check_docker
if errorlevel 1 exit /b 1

echo ℹ️  Building Docker image: %IMAGE_NAME%:%IMAGE_TAG%
call :create_dockerignore

docker build -t %IMAGE_NAME%:%IMAGE_TAG% .
if errorlevel 1 (
    echo ❌ Failed to build Docker image
    pause
    exit /b 1
) else (
    echo ✅ Docker image built successfully
)
goto end

:run
call :check_docker
if errorlevel 1 exit /b 1

call :build
if errorlevel 1 exit /b 1

echo ℹ️  Running Docker container: %CONTAINER_NAME%

REM Stop and remove existing container if it exists
docker ps -a --format "table {{.Names}}" | findstr /B /C:"%CONTAINER_NAME%" >nul 2>&1
if not errorlevel 1 (
    echo ⚠️  Stopping and removing existing container
    docker stop %CONTAINER_NAME% >nul 2>&1
    docker rm %CONTAINER_NAME% >nul 2>&1
)

REM Check if .env file exists
set ENV_MOUNT=
if exist ".env" (
    set ENV_MOUNT=-v %CD%\.env:/app/.env
    echo ℹ️  Mounting .env file
) else (
    echo ⚠️  .env file not found - container will run without environment variables
)

REM Run the container
docker run -d --name %CONTAINER_NAME% -p %PORT%:3010 %ENV_MOUNT% %IMAGE_NAME%:%IMAGE_TAG%
if errorlevel 1 (
    echo ❌ Failed to start container
    pause
    exit /b 1
) else (
    echo ✅ Container started successfully
    echo ℹ️  Access the API at: http://localhost:%PORT%
    echo ℹ️  Container name: %CONTAINER_NAME%
)
goto end

:stop
call :check_docker
if errorlevel 1 exit /b 1

echo ℹ️  Stopping container: %CONTAINER_NAME%
docker stop %CONTAINER_NAME% >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Container was not running or does not exist
) else (
    echo ✅ Container stopped
)
goto end

:restart
call :check_docker
if errorlevel 1 exit /b 1

echo ℹ️  Restarting container...
call :stop
docker rm %CONTAINER_NAME% >nul 2>&1
call :run
goto end

:logs
call :check_docker
if errorlevel 1 exit /b 1

echo ℹ️  Showing logs for container: %CONTAINER_NAME%
docker logs -f %CONTAINER_NAME%
if errorlevel 1 (
    echo ❌ Container does not exist or is not running
    pause
)
goto end

:status
call :check_docker
if errorlevel 1 exit /b 1

echo ℹ️  Container status:
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr %CONTAINER_NAME%
if errorlevel 1 (
    echo ⚠️  Container is not running
)

echo.
echo ℹ️  Available images:
docker images | findstr %IMAGE_NAME%
if errorlevel 1 (
    echo ⚠️  No images found
)
goto end

:push
call :check_docker
if errorlevel 1 exit /b 1

if "%REGISTRY_USER%"=="" (
    echo ❌ REGISTRY_USER is not set in this script
    echo ℹ️  Please edit the script and set your Docker Hub username
    pause
    exit /b 1
)

echo ℹ️  Tagging image for registry
docker tag %IMAGE_NAME%:%IMAGE_TAG% %REGISTRY_USER%/%IMAGE_NAME%:%IMAGE_TAG%

echo ℹ️  Pushing to Docker Hub: %REGISTRY_USER%/%IMAGE_NAME%:%IMAGE_TAG%
docker push %REGISTRY_USER%/%IMAGE_NAME%:%IMAGE_TAG%
if errorlevel 1 (
    echo ❌ Failed to push image
    pause
    exit /b 1
) else (
    echo ✅ Image pushed successfully
    echo ℹ️  Pull command: docker pull %REGISTRY_USER%/%IMAGE_NAME%:%IMAGE_TAG%
)
goto end

:cleanup
call :check_docker
if errorlevel 1 exit /b 1

echo ℹ️  Cleaning up Docker resources

REM Stop and remove container
docker stop %CONTAINER_NAME% >nul 2>&1
docker rm %CONTAINER_NAME% >nul 2>&1

REM Remove image
docker rmi %IMAGE_NAME%:%IMAGE_TAG% >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Image does not exist
) else (
    echo ✅ Image removed
)

REM Clean up unused resources
echo ℹ️  Cleaning up unused Docker resources
docker system prune -f
goto end

:help
echo Usage: %0 [COMMAND]
echo.
echo Commands:
echo   build     Build Docker image
echo   run       Run Docker container
echo   stop      Stop Docker container
echo   restart   Restart Docker container
echo   logs      Show container logs
echo   status    Show container and image status
echo   push      Push image to Docker Hub
echo   cleanup   Stop container and remove image
echo   help      Show this help
echo.
echo Examples:
echo   %0 build
echo   %0 run
echo   %0 logs
goto end

:end
echo =========================================
if not "%COMMAND%"=="logs" pause 