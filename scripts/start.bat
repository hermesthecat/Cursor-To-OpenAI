@echo off
title Cursor To OpenAI Server

echo ===================================
echo   Cursor To OpenAI Server Startup  
echo ===================================

REM Check if .env file exists
if not exist "..\.env" (
    echo ⚠️  .env file not found!
    echo 📝 Please run 'npm run login' first to get your Cursor token
    echo    or manually create .env file with CURSOR_TOKEN=your_token
    pause
    exit /b 1
)

REM Check if CURSOR_TOKEN is set in .env
findstr /C:"CURSOR_TOKEN=" ..\.env >nul
if errorlevel 1 (
    echo ⚠️  CURSOR_TOKEN not found in .env file!
    echo 📝 Please run 'npm run login' to get your Cursor token
    pause
    exit /b 1
)

REM Check if CURSOR_TOKEN has a value (basic check)
for /f "tokens=2 delims==" %%a in ('findstr /C:"CURSOR_TOKEN=" ..\.env') do set TOKEN_VALUE=%%a
if "%TOKEN_VALUE%"=="" (
    echo ⚠️  CURSOR_TOKEN is empty in .env file!
    echo 📝 Please run 'npm run login' to get your Cursor token
    pause
    exit /b 1
)

echo ✅ .env file found with CURSOR_TOKEN
echo 🚀 Starting Cursor To OpenAI server...
echo.

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo 📦 Installing dependencies...
    call npm install
    echo.
)

REM Start the server
echo 🌟 Server starting on http://localhost:3010
echo.
echo Press Ctrl+C to stop the server
echo ===================================

call npm start 