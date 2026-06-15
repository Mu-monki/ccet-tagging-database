# ==========================================
# Starting CCET Database Setup (Windows)
# ==========================================

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Starting CCET Database Setup (Windows)   " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Check Prerequisites
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: Docker is not installed or not in your PATH." -ForegroundColor Red
    exit
}

if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: Python is not installed or not in your PATH." -ForegroundColor Red
    exit
}

# 2. Install Python Dependencies
Write-Host "📦 Installing Python dependencies..." -ForegroundColor Yellow
pip install pandas sqlalchemy pymysql openpyxl

# 3. Start Docker Container (Auto-detect compose version)
Write-Host "🐳 Detecting Docker Compose version..." -ForegroundColor Yellow

# Check for the newer docker compose plugin
$dockerComposePlugin = docker compose version 2>$null | Out-String
if (-not [string]::IsNullOrWhiteSpace($dockerComposePlugin)) {
    $DockerComposeCmd = "docker compose"
} 
# Fallback to the old standalone docker-compose
elseif (Get-Command "docker-compose" -ErrorAction SilentlyContinue) {
    $DockerComposeCmd = "docker-compose"
} 
else {
    Write-Host "❌ Error: Neither 'docker compose' nor 'docker-compose' is installed." -ForegroundColor Red
    exit
}

Write-Host "Starting MySQL using: $DockerComposeCmd up -d" -ForegroundColor Yellow
Invoke-Expression "$DockerComposeCmd up -d"

# 4. Wait for MySQL to initialize
Write-Host "⏳ Waiting for MySQL to initialize (20 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# 5. Apply SQL Schema
Write-Host "🏗️  Applying SQL Schema (Creating tables and relationships)..." -ForegroundColor Yellow
# Read the SQL file and pipe it to the MySQL client inside the container
cmd.exe /c "type schema.sql | docker exec -i ccet_mysql mysql -uroot -prootpassword ccet_db"

# 6. Run Python Data Migration
Write-Host "🚀 Running Python Data Migration Script..." -ForegroundColor Yellow
python migration.py

Write-Host "==========================================" -ForegroundColor Green
Write-Host "✅ Setup Complete! Database is ready at localhost:3306" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green