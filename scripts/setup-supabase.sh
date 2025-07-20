#!/bin/bash

# Brainy Backend API - Supabase Setup Script
# This script helps set up the Supabase development environment

set -e

echo "🚀 Setting up Brainy Backend API with Supabase..."

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "📦 Installing Supabase CLI..."
    
    # Detect OS and install accordingly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install supabase/tap/supabase
        else
            echo "❌ Homebrew not found. Please install Homebrew first or install Supabase CLI manually."
            echo "Visit: https://supabase.com/docs/guides/cli"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -fsSL https://supabase.com/install.sh | sh
    else
        echo "❌ Unsupported OS. Please install Supabase CLI manually."
        echo "Visit: https://supabase.com/docs/guides/cli"
        exit 1
    fi
else
    echo "✅ Supabase CLI is already installed"
fi

# Verify installation
echo "📋 Supabase CLI version:"
supabase --version

# Check if we're in the right directory
if [ ! -f "supabase/config.toml" ]; then
    echo "❌ supabase/config.toml not found. Make sure you're in the project root directory."
    exit 1
fi

# Initialize local environment if not already done
if [ ! -d "supabase/.temp" ]; then
    echo "🔧 Starting Supabase local development environment..."
    cd supabase
    supabase start
    cd ..
else
    echo "✅ Supabase local environment already initialized"
fi

# Create .env.local if it doesn't exist
if [ ! -f ".env.local" ]; then
    echo "📝 Creating .env.local from example..."
    cp .env.local.example .env.local
    echo "⚠️  Please update .env.local with your actual API keys"
else
    echo "✅ .env.local already exists"
fi

echo ""
echo "🎉 Supabase setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Update .env.local with your API keys"
echo "2. Run 'supabase status' to check local services"
echo "3. Access Supabase Studio at http://localhost:54323"
echo "4. Run database migrations when ready"
echo ""
echo "🔗 Useful commands:"
echo "  supabase start    - Start local development environment"
echo "  supabase stop     - Stop local development environment"
echo "  supabase status   - Check status of local services"
echo "  supabase db reset - Reset local database"
echo ""