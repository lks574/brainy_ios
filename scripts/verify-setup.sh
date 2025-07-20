#!/bin/bash

# Setup Verification Script
# Checks if all required files and configurations are in place

set -e

echo "🔍 Verifying Brainy Backend API setup..."

# Check if Supabase CLI is installed
if command -v supabase &> /dev/null; then
    echo "✅ Supabase CLI installed ($(supabase --version))"
else
    echo "❌ Supabase CLI not found"
    exit 1
fi

# Check required files
required_files=(
    "supabase/config.toml"
    ".env.local.example"
    ".env.production.example"
    "package.json"
    "tsconfig.json"
    "types/database.ts"
    "scripts/setup-supabase.sh"
    "scripts/check-db-connection.sh"
    "supabase/README.md"
    "README.md"
)

echo "📋 Checking required files..."
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Check if .env.local exists
if [ -f ".env.local" ]; then
    echo "✅ .env.local exists"
else
    echo "⚠️  .env.local not found (will be created on first run)"
fi

# Check Docker
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        echo "✅ Docker is running"
    else
        echo "⚠️  Docker is installed but not running"
    fi
else
    echo "❌ Docker not found - required for local development"
fi

# Check Node.js
if command -v node &> /dev/null; then
    echo "✅ Node.js installed ($(node --version))"
else
    echo "⚠️  Node.js not found - recommended for development"
fi

echo ""
echo "🎉 Setup verification completed!"
echo ""
echo "📋 Next steps:"
echo "1. Start Docker if not running"
echo "2. Run 'npm run dev' to start Supabase"
echo "3. Update .env.local with your API keys"
echo "4. Run 'npm run check-db' to verify connection"
echo ""