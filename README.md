# Brainy Backend API

Backend API for the Brainy iOS Quiz App built with Supabase.

## Features

- 🔐 **Authentication**: Email, Google OAuth, Apple Sign-in
- 📊 **Quiz Management**: Dynamic quiz data with versioning
- 🔄 **Real-time Sync**: Progress synchronization across devices
- 🤖 **AI Integration**: OpenAI-powered quiz generation
- 📈 **Analytics**: User progress tracking and statistics
- 🛡️ **Security**: Row Level Security (RLS) and JWT authentication

## Quick Start

### Prerequisites

- Node.js 18+
- Docker (for local Supabase)
- Git

### Setup

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd brainy-backend-api
   npm run setup
   ```

2. **Configure environment:**
   ```bash
   cp .env.local.example .env.local
   # Update .env.local with your API keys
   ```

3. **Start development:**
   ```bash
   npm run dev
   ```

4. **Verify setup:**
   ```bash
   npm run check-db
   npm run status
   ```

## Development

### Available Scripts

```bash
npm run setup          # Initial project setup
npm run dev           # Start Supabase local environment
npm run stop          # Stop all services
npm run status        # Check service status
npm run check-db      # Verify database connection
npm run studio        # Open Supabase Studio
npm run reset         # Reset local database
```

### Database Management

```bash
npm run db:diff       # Generate migration
npm run db:push       # Apply migrations
npm run db:pull       # Pull remote schema
npm run gen:types     # Generate TypeScript types
```

### Edge Functions

```bash
npm run functions:serve    # Serve functions locally
npm run functions:new      # Create new function
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    iOS App (Client)                        │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTPS/WebSocket
┌─────────────────────▼───────────────────────────────────────┐
│                 API Gateway                                 │
│              (Supabase Edge Functions)                      │
├─────────────────────────────────────────────────────────────┤
│                 Authentication                              │
│                (Supabase Auth)                             │
├─────────────────────────────────────────────────────────────┤
│                 Business Logic                              │
│            (Custom API Functions)                           │
├─────────────────────────────────────────────────────────────┤
│                 Data Layer                                  │
│              (PostgreSQL + Supabase)                       │
└─────────────────────────────────────────────────────────────┘
```

## API Endpoints

### Authentication
- `POST /auth/v1/signup` - User registration
- `POST /auth/v1/token` - Login
- `POST /auth/v1/logout` - Logout
- `GET /auth/v1/user` - Get user profile

### Quiz Data
- `GET /api/v1/quiz/version` - Check quiz version
- `GET /api/v1/quiz/data` - Download quiz data
- `GET /api/v1/quiz/categories` - Get categories
- `POST /api/v1/quiz/ai-generate` - Generate AI quiz

### User Progress
- `POST /api/v1/sync/progress` - Upload progress
- `GET /api/v1/sync/progress` - Download progress
- `GET /api/v1/history` - Get quiz history
- `GET /api/v1/statistics` - Get user statistics

### Admin
- `POST /api/v1/admin/auth` - Admin login
- `GET /api/v1/admin/users` - List users
- `POST /api/v1/admin/quiz/create` - Create quiz
- `PUT /api/v1/admin/quiz/:id` - Update quiz

## Database Schema

### Core Tables
- `users` - User accounts and profiles
- `quiz_questions` - Quiz questions and answers
- `quiz_results` - Individual question results
- `quiz_sessions` - Quiz session data
- `quiz_versions` - Version management

## Security

- **Authentication**: JWT tokens with Supabase Auth
- **Authorization**: Row Level Security (RLS) policies
- **Data Protection**: HTTPS/TLS encryption
- **Input Validation**: Schema validation for all inputs
- **Rate Limiting**: API request throttling

## Deployment

### Production Setup

1. **Create Supabase project:**
   - Go to [Supabase Dashboard](https://app.supabase.com)
   - Create new project
   - Note project URL and API keys

2. **Configure production environment:**
   ```bash
   cp .env.production.example .env.production
   # Update with production values
   ```

3. **Deploy database schema:**
   ```bash
   supabase link --project-ref your-project-ref
   supabase db push
   ```

4. **Deploy Edge Functions:**
   ```bash
   supabase functions deploy
   ```

## Monitoring

- **Health Checks**: `/health` endpoint
- **Logging**: Structured logging with Supabase
- **Metrics**: Performance and usage analytics
- **Alerts**: Error monitoring and notifications

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](./supabase/README.md)
- 🐛 [Issue Tracker](https://github.com/your-repo/issues)
- 💬 [Discussions](https://github.com/your-repo/discussions)

---

Built with ❤️ using [Supabase](https://supabase.com)