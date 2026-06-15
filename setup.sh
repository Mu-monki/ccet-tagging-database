#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=========================================="
echo " Starting CCET Database Setup (macOS/Linux)"
echo "=========================================="

# 1. Check Prerequisites
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not running."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python3 is not installed."
    exit 1
fi

# 2. Install Python Dependencies
echo "📦 Installing Python dependencies..."
pip3 install pandas sqlalchemy pymysql openpyxl

# 3. Start Docker Container (Auto-detect compose version)
echo "🐳 Detecting Docker Compose version..."

if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
elif docker-compose --version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    echo "❌ Error: Neither 'docker compose' nor 'docker-compose' is installed."
    exit 1
fi

echo "Starting MySQL using: $DOCKER_COMPOSE_CMD up -d"
$DOCKER_COMPOSE_CMD up -d

# 4. Wait for MySQL to initialize (It takes ~15-20 seconds to be ready for connections)
echo "⏳ Waiting for MySQL to initialize (20 seconds)..."
sleep 20

# 5. Apply SQL Schema
echo "🏗️  Applying SQL Schema (Creating tables and relationships)..."
# We pipe the schema.sql file directly into the docker container's mysql client
docker exec -i ccet_mysql mysql -uroot -prootpassword ccet_db < schema.sql

# 6. Run Python Data Migration
echo "🚀 Running Python Data Migration Script..."
python3 migration.py

echo "=========================================="
echo "✅ Setup Complete! Database is ready at localhost:3306"
echo "=========================================="