# Cursor To OpenAI - Windows Service Installation Script
# Requires Administrator privileges

param(
    [string]$ServiceName = "CursorToOpenAI",
    [string]$DisplayName = "Cursor To OpenAI API Service",
    [string]$Description = "Converts Cursor Editor AI to OpenAI API interface"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Cursor To OpenAI Service Installer    " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script must be run as Administrator" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "   Then run: .\scripts\service_install.ps1" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Get current directory
$ProjectDir = Get-Location
$NodeExe = (Get-Command node -ErrorAction SilentlyContinue).Source
$AppJs = Join-Path $ProjectDir "src\app.js"
$EnvFile = Join-Path $ProjectDir ".env"

Write-Host "📁 Project directory: $ProjectDir" -ForegroundColor Green
Write-Host "🔧 Service name: $ServiceName" -ForegroundColor Green

# Check if Node.js is installed
if (-not $NodeExe) {
    Write-Host "❌ Node.js is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Node.js found: $NodeExe" -ForegroundColor Green

# Check if .env file exists
if (-not (Test-Path $EnvFile)) {
    Write-Host "⚠️  .env file not found in $ProjectDir" -ForegroundColor Yellow
    Write-Host "📝 Please run 'npm run login' first to get your Cursor token" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if CURSOR_TOKEN is set
$EnvContent = Get-Content $EnvFile -Raw
if (-not ($EnvContent -match "CURSOR_TOKEN=")) {
    Write-Host "⚠️  CURSOR_TOKEN not found in .env file!" -ForegroundColor Yellow
    Write-Host "📝 Please run 'npm run login' to get your Cursor token" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ .env file found with CURSOR_TOKEN" -ForegroundColor Green

# Install dependencies if needed
$NodeModules = Join-Path $ProjectDir "node_modules"
if (-not (Test-Path $NodeModules)) {
    Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Check if NSSM is available
$NssmExe = $null
$NssmPaths = @(
    "nssm.exe",
    "C:\nssm\win64\nssm.exe",
    "C:\nssm\win32\nssm.exe",
    "C:\Program Files\nssm\nssm.exe",
    "C:\Program Files (x86)\nssm\nssm.exe"
)

foreach ($path in $NssmPaths) {
    if (Get-Command $path -ErrorAction SilentlyContinue) {
        $NssmExe = $path
        break
    }
}

if (-not $NssmExe) {
    Write-Host "📥 NSSM not found. Downloading..." -ForegroundColor Yellow
    
    # Create temp directory
    $TempDir = Join-Path $env:TEMP "nssm_download"
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    
    # Download NSSM
    $NssmZip = Join-Path $TempDir "nssm.zip"
    $NssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
    
    try {
        Write-Host "   Downloading from $NssmUrl..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $NssmUrl -OutFile $NssmZip -UseBasicParsing
        
        # Extract NSSM
        Write-Host "   Extracting NSSM..." -ForegroundColor Gray
        Expand-Archive -Path $NssmZip -DestinationPath $TempDir -Force
        
        # Determine architecture
        $Arch = if ([Environment]::Is64BitOperatingSystem) { "win64" } else { "win32" }
        $NssmExe = Join-Path $TempDir "nssm-2.24\$Arch\nssm.exe"
        
        if (-not (Test-Path $NssmExe)) {
            throw "NSSM executable not found after extraction"
        }
        
        Write-Host "✅ NSSM downloaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to download NSSM: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Please download NSSM manually from https://nssm.cc/" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host "✅ NSSM found: $NssmExe" -ForegroundColor Green

# Stop and remove existing service if it exists
$ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($ExistingService) {
    Write-Host "🛑 Stopping existing service..." -ForegroundColor Yellow
    & $NssmExe stop $ServiceName
    Start-Sleep -Seconds 2
    
    Write-Host "🗑️  Removing existing service..." -ForegroundColor Yellow
    & $NssmExe remove $ServiceName confirm
}

# Install the service
Write-Host "📝 Installing Windows service..." -ForegroundColor Yellow
& $NssmExe install $ServiceName $NodeExe $AppJs

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install service" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Configure service
Write-Host "⚙️  Configuring service..." -ForegroundColor Yellow
& $NssmExe set $ServiceName DisplayName $DisplayName
& $NssmExe set $ServiceName Description $Description
& $NssmExe set $ServiceName Start SERVICE_AUTO_START
& $NssmExe set $ServiceName AppDirectory $ProjectDir
& $NssmExe set $ServiceName AppEnvironmentExtra "NODE_ENV=production"

# Set up logging
$LogDir = Join-Path $ProjectDir "logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

& $NssmExe set $ServiceName AppStdout (Join-Path $LogDir "service.log")
& $NssmExe set $ServiceName AppStderr (Join-Path $LogDir "service_error.log")
& $NssmExe set $ServiceName AppRotateFiles 1
& $NssmExe set $ServiceName AppRotateOnline 1
& $NssmExe set $ServiceName AppRotateSeconds 86400
& $NssmExe set $ServiceName AppRotateBytes 1048576

# Start the service
Write-Host "▶️  Starting service..." -ForegroundColor Yellow
& $NssmExe start $ServiceName

Start-Sleep -Seconds 3

# Check service status
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($Service -and $Service.Status -eq "Running") {
    Write-Host "✅ Service installed and started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Service Management Commands:" -ForegroundColor Cyan
    Write-Host "   Start:   net start $ServiceName" -ForegroundColor Gray
    Write-Host "   Stop:    net stop $ServiceName" -ForegroundColor Gray
    Write-Host "   Restart: net stop $ServiceName && net start $ServiceName" -ForegroundColor Gray
    Write-Host "   Status:  Get-Service $ServiceName" -ForegroundColor Gray
    Write-Host "   Logs:    Get-Content logs\service.log -Tail 50 -Wait" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🌐 Service is running on: http://localhost:3010" -ForegroundColor Green
    Write-Host ""
    Write-Host "🗑️  To uninstall: .\scripts\service_uninstall.ps1" -ForegroundColor Yellow
} else {
    Write-Host "❌ Service failed to start!" -ForegroundColor Red
    Write-Host "📋 Check logs in: $LogDir" -ForegroundColor Yellow
    if (Test-Path (Join-Path $LogDir "service_error.log")) {
        Write-Host "Error log:" -ForegroundColor Red
        Get-Content (Join-Path $LogDir "service_error.log") | Select-Object -Last 10
    }
}

Write-Host "=========================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit" 