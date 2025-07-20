# Brainy Backend API - Supabase Setup

This directory contains the Supabase configuration and setup for the Brainy Backend API.

## Quick Start

1. **Run the setup script:**
   ```bash
   ./scripts/setup-supabase.sh
   ```

2. **Update environment variables:**
   - Copy `.env.local.example` to `.env.local`
   - Update the values with your actual API keys

3. **Start local development:**
   ```bash
   supabase start
   ```

## Manual Setup

If you prefer to set up manually:

### 1. Install Supabase CLI

**macOS (with Homebrew):**
```bash
brew install supabase/tap/supabase
```

**Linux:**
```bash
curl -fsSL https://supabase.com/install.sh | sh
```

**Other platforms:**
Visit [Supabase CLI documentation](https://supabase.com/docs/guides/cli)

### 2. Initialize Local Environment

```bash
cd supabase
supabase start
```

### 3. Verify Setup

```bash
supabase status
```

You should see all services running:
- API URL: http://localhost:54321
- Studio URL: http://localhost:54323
- Database URL: postgresql://postgres:postgres@localhost:54322/postgres

## Configuration

### Environment Variables

The project uses different environment files:

- `.env.local` - Local development
- `.env.production` - Production deployment

### Supabase Configuration

The `config.toml` file contains:

- **Database settings**: PostgreSQL configuration
- **API settings**: REST API and GraphQL configuration
- **Auth settings**: Authentication providers and policies
- **Storage settings**: File upload limits and configuration
- **Realtime settings**: WebSocket configuration

### Authentication Providers

Configured providers:
- Email/Password (default)
- Google OAuth
- Apple Sign-in

To enable OAuth providers, update your environment variables with the respective client IDs and secrets.

## Development Workflow

### Starting Development

```bash
# Start all Supabase services
supabase start

# Check status
supabase status

# Access Studio (Database UI)
open http://localhost:54323
```

### Database Management

```bash
# Reset database (careful - this deletes all data)
supabase db reset

# Generate migration
supabase db diff --file migration_name

# Apply migrations
supabase db push
```

### Edge Functions

```bash
# Create new function
supabase functions new function_name

# Deploy function locally
supabase functions serve

# Deploy to production
supabase functions deploy function_name
```

### Stopping Services

```bash
supabase stop
```

## Production Deployment

### 1. Create Supabase Project

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Create a new project
3. Note down your project URL and API keys

### 2. Update Production Environment

Update `.env.production` with your production values:
- `SUPABASE_URL`: Your project URL
- `SUPABASE_ANON_KEY`: Your anon/public key
- `SUPABASE_SERVICE_ROLE_KEY`: Your service role key

### 3. Deploy Database Schema

```bash
# Link to your project
supabase link --project-ref your-project-ref

# Push database changes
supabase db push

# Deploy functions
supabase functions deploy
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: If ports are in use, update `config.toml`
2. **Docker issues**: Make sure Docker is running
3. **Permission errors**: Check file permissions for scripts

### Useful Commands

```bash
# View logs
supabase logs

# Check service health
curl http://localhost:54321/health

# Reset everything
supabase stop
supabase start
```

### Getting Help

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [Community Discord](https://discord.supabase.com)

## Project Structure

```
supabase/
├── config.toml          # Main configuration
├── migrations/          # Database migrations
├── functions/           # Edge Functions
├── seed.sql            # Seed data
└── README.md           # This file
```

## Security Notes

- Never commit `.env.local` or `.env.production` files
- Use environment variables for all secrets
- Enable Row Level Security (RLS) for all tables
- Regularly rotate API keys
- Monitor usage and set up alerts