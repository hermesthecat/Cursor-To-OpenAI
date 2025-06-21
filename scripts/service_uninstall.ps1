# Cursor To OpenAI - Windows Service Uninstallation Script
# Requires Administrator privileges

param(
    [string]$ServiceName = "CursorToOpenAI"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Cursor To OpenAI Service Uninstaller   " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script must be run as Administrator" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "   Then run: .\scripts\service_uninstall.ps1" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "🔧 Service name: $ServiceName" -ForegroundColor Green

# Check if service exists
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $Service) {
    Write-Host "⚠️  Service $ServiceName is not installed" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
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

# Try to find NSSM in temp directory (from previous installation)
if (-not $NssmExe) {
    $TempDir = Join-Path $env:TEMP "nssm_download"
    $Arch = if ([Environment]::Is64BitOperatingSystem) { "win64" } else { "win32" }
    $TempNssm = Join-Path $TempDir "nssm-2.24\$Arch\nssm.exe"
    
    if (Test-Path $TempNssm) {
        $NssmExe = $TempNssm
    }
}

if (-not $NssmExe) {
    Write-Host "❌ NSSM not found!" -ForegroundColor Red
    Write-Host "   Cannot uninstall service without NSSM" -ForegroundColor Yellow
    Write-Host "   You can try to remove the service manually:" -ForegroundColor Yellow
    Write-Host "   sc delete $ServiceName" -ForegroundColor Gray
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ NSSM found: $NssmExe" -ForegroundColor Green

# Stop the service if running
if ($Service.Status -eq "Running") {
    Write-Host "🛑 Stopping $ServiceName service..." -ForegroundColor Yellow
    try {
        & $NssmExe stop $ServiceName
        Start-Sleep -Seconds 3
        Write-Host "✅ Service stopped" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Failed to stop service gracefully, forcing stop..." -ForegroundColor Yellow
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "ℹ️  Service $ServiceName is not running" -ForegroundColor Gray
}

# Remove the service
Write-Host "🗑️  Removing service..." -ForegroundColor Yellow
try {
    & $NssmExe remove $ServiceName confirm
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Service removed successfully" -ForegroundColor Green
    } else {
        throw "NSSM remove command failed"
    }
}
catch {
    Write-Host "⚠️  NSSM removal failed, trying Windows SC command..." -ForegroundColor Yellow
    & sc.exe delete $ServiceName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Service removed using SC command" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to remove service" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Ask about removing log files
$LogDir = Join-Path (Get-Location) "logs"
if (Test-Path $LogDir) {
    Write-Host ""
    $RemoveLogs = Read-Host "🤔 Do you want to remove log files in '$LogDir'? (y/N)"
    if ($RemoveLogs -match "^[Yy]$") {
        try {
            Remove-Item -Path $LogDir -Recurse -Force
            Write-Host "🗑️  Log files removed" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  Could not remove log files: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "ℹ️  Log files kept in: $LogDir" -ForegroundColor Gray
    }
}

# Ask about removing NSSM temp files
$TempDir = Join-Path $env:TEMP "nssm_download"
if (Test-Path $TempDir) {
    Write-Host ""
    $RemoveNssm = Read-Host "🤔 Do you want to remove NSSM temp files? (y/N)"
    if ($RemoveNssm -match "^[Yy]$") {
        try {
            Remove-Item -Path $TempDir -Recurse -Force
            Write-Host "🗑️  NSSM temp files removed" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  Could not remove NSSM temp files: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "ℹ️  NSSM files kept in: $TempDir" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "✅ Service $ServiceName has been uninstalled successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Note: Project files are kept in place" -ForegroundColor Gray
Write-Host "   You can still run the application manually with: npm start" -ForegroundColor Gray
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit" 