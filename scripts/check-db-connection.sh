#!/bin/bash

# Database Connection Check Script
# Verifies that Supabase local database is accessible

set -e

echo "🔍 Checking Supabase database connection..."

# Check if Supabase is running
if ! curl -s http://localhost:54321/health > /dev/null; then
    echo "❌ Supabase API is not running. Please run 'supabase start' first."
    exit 1
fi

echo "✅ Supabase API is running"

# Check database connection using psql if available
if command -v psql &> /dev/null; then
    echo "🔍 Testing direct database connection..."
    
    # Test connection
    if PGPASSWORD=postgres psql -h localhost -p 54322 -U postgres -d postgres -c "SELECT version();" > /dev/null 2>&1; then
        echo "✅ Database connection successful"
        
        # Get database version
        echo "📋 Database info:"
        PGPASSWORD=postgres psql -h localhost -p 54322 -U postgres -d postgres -c "SELECT version();" -t | head -1
    else
        echo "❌ Database connection failed"
        exit 1
    fi
else
    echo "⚠️  psql not found, skipping direct database test"
fi

# Test API endpoints
echo "🔍 Testing API endpoints..."

# Test health endpoint
if curl -s http://localhost:54321/health | grep -q "ok"; then
    echo "✅ Health endpoint working"
else
    echo "❌ Health endpoint failed"
fi

# Test REST API
if curl -s http://localhost:54321/rest/v1/ > /dev/null; then
    echo "✅ REST API accessible"
else
    echo "❌ REST API not accessible"
fi

echo ""
echo "🎉 Database connection check completed!"
echo ""
echo "📋 Service URLs:"
echo "  API: http://localhost:54321"
echo "  Studio: http://localhost:54323"
echo "  Database: postgresql://postgres:postgres@localhost:54322/postgres"
echo ""