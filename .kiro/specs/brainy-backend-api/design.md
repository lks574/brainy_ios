# Design Document

## Overview

Brainy Backend API는 Supabase를 기반으로 구축되는 RESTful API 서비스입니다. PostgreSQL 데이터베이스와 실시간 기능을 활용하여 iOS 퀴즈 앱의 백엔드 요구사항을 충족합니다. 마이크로서비스 아키텍처를 적용하여 확장성과 유지보수성을 보장하며, 오프라인 우선 설계를 고려한 효율적인 데이터 동기화를 제공합니다.

## Architecture

### System Architecture

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
├─────────────────────────────────────────────────────────────┤
│                 External Services                           │
│         (OpenAI API, File Storage, Monitoring)             │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

```
Frontend: iOS App (Swift 6 + SwiftUI)
Backend: Supabase (PostgreSQL + Edge Functions)
Authentication: Supabase Auth
Real-time: Supabase Realtime
Storage: Supabase Storage
AI: OpenAI API
Monitoring: Supabase Analytics
Deployment: Supabase Cloud
```

## Components and Interfaces

### Authentication Service

#### Endpoints
```typescript
POST /auth/v1/signup
POST /auth/v1/token
POST /auth/v1/logout
GET  /auth/v1/user
PUT  /auth/v1/user
```

#### Authentication Flow
```typescript
interface AuthRequest {
  email: string;
  password: string;
  provider?: 'email' | 'google' | 'apple';
  token?: string; // OAuth token for social login
}

interface AuthResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  user: {
    id: string;
    email: string;
    display_name: string;
    auth_provider: string;
    created_at: string;
  };
}
```

### Quiz Data Service

#### Endpoints
```typescript
GET  /api/v1/quiz/version
GET  /api/v1/quiz/data
GET  /api/v1/quiz/categories
GET  /api/v1/quiz/questions/:category
POST /api/v1/quiz/ai-generate
```

#### Quiz Data Models
```typescript
interface QuizVersion {
  version: string;
  last_updated: string;
  categories: string[];
}

interface QuizQuestion {
  id: string;
  question: string;
  correct_answer: string;
  options?: string[];
  category: QuizCategory;
  difficulty: QuizDifficulty;
  type: QuizType;
  audio_url?: string;
  version: string;
  created_at: string;
}

interface QuizDataResponse {
  version: string;
  questions: QuizQuestion[];
  total_count: number;
}
```

### User Progress Service

#### Endpoints
```typescript
POST /api/v1/sync/progress
GET  /api/v1/sync/progress
POST /api/v1/sync/batch
GET  /api/v1/history
GET  /api/v1/history/:session_id
GET  /api/v1/statistics
```

#### Progress Data Models
```typescript
interface QuizResult {
  id: string;
  user_id: string;
  question_id: string;
  user_answer: string;
  is_correct: boolean;
  time_spent: number;
  completed_at: string;
  category: string;
  quiz_mode: string;
}

interface QuizSession {
  id: string;
  user_id: string;
  category: string;
  mode: string;
  total_questions: number;
  correct_answers: number;
  total_time: number;
  started_at: string;
  completed_at?: string;
  results: QuizResult[];
}

interface SyncRequest {
  sessions: QuizSession[];
  results: QuizResult[];
  last_sync_at?: string;
}
```

### AI Quiz Generation Service

#### Endpoints
```typescript
POST /api/v1/ai/generate-quiz
POST /api/v1/ai/validate-question
GET  /api/v1/ai/usage
```

#### AI Integration
```typescript
interface AIQuizRequest {
  category: string;
  difficulty: 'easy' | 'medium' | 'hard';
  type: 'multiple_choice' | 'short_answer';
  count: number;
  language: 'ko' | 'en';
}

interface AIQuizResponse {
  questions: QuizQuestion[];
  generation_time: number;
  tokens_used: number;
}
```

### Admin Service

#### Endpoints
```typescript
POST /api/v1/admin/auth
GET  /api/v1/admin/users
GET  /api/v1/admin/statistics
POST /api/v1/admin/quiz/create
PUT  /api/v1/admin/quiz/:id
DELETE /api/v1/admin/quiz/:id
POST /api/v1/admin/quiz/bulk-import
```

## Data Models

### Database Schema

#### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE,
  display_name VARCHAR(100) NOT NULL,
  auth_provider VARCHAR(20) NOT NULL DEFAULT 'email',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_sync_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}'
);
```

#### Quiz Questions Table
```sql
CREATE TABLE quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  options JSONB, -- Array of options for multiple choice
  category VARCHAR(50) NOT NULL,
  difficulty VARCHAR(20) NOT NULL DEFAULT 'medium',
  type VARCHAR(30) NOT NULL DEFAULT 'multiple_choice',
  audio_url TEXT,
  version VARCHAR(20) NOT NULL DEFAULT '1.0.0',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Quiz Results Table
```sql
CREATE TABLE quiz_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  question_id UUID REFERENCES quiz_questions(id),
  session_id UUID REFERENCES quiz_sessions(id),
  user_answer TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  time_spent INTEGER NOT NULL, -- in seconds
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Quiz Sessions Table
```sql
CREATE TABLE quiz_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(50) NOT NULL,
  mode VARCHAR(30) NOT NULL,
  total_questions INTEGER NOT NULL,
  correct_answers INTEGER DEFAULT 0,
  total_time INTEGER DEFAULT 0, -- in seconds
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}'
);
```

#### Quiz Versions Table
```sql
CREATE TABLE quiz_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  question_count INTEGER DEFAULT 0,
  is_current BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Indexes and Performance

```sql
-- Performance indexes
CREATE INDEX idx_quiz_questions_category ON quiz_questions(category);
CREATE INDEX idx_quiz_questions_active ON quiz_questions(is_active);
CREATE INDEX idx_quiz_results_user_id ON quiz_results(user_id);
CREATE INDEX idx_quiz_results_completed_at ON quiz_results(completed_at);
CREATE INDEX idx_quiz_sessions_user_id ON quiz_sessions(user_id);
CREATE INDEX idx_quiz_sessions_completed_at ON quiz_sessions(completed_at);

-- Composite indexes
CREATE INDEX idx_quiz_questions_category_type ON quiz_questions(category, type);
CREATE INDEX idx_quiz_results_user_session ON quiz_results(user_id, session_id);
```

## API Design

### RESTful API Conventions

#### HTTP Methods
- GET: 데이터 조회
- POST: 새 리소스 생성
- PUT: 전체 리소스 업데이트
- PATCH: 부분 리소스 업데이트
- DELETE: 리소스 삭제

#### Response Format
```typescript
interface APIResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
  meta?: {
    total_count?: number;
    page?: number;
    per_page?: number;
    version?: string;
  };
}
```

#### Error Handling
```typescript
enum ErrorCodes {
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  AUTHENTICATION_FAILED = 'AUTHENTICATION_FAILED',
  AUTHORIZATION_FAILED = 'AUTHORIZATION_FAILED',
  RESOURCE_NOT_FOUND = 'RESOURCE_NOT_FOUND',
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  INTERNAL_SERVER_ERROR = 'INTERNAL_SERVER_ERROR',
  EXTERNAL_SERVICE_ERROR = 'EXTERNAL_SERVICE_ERROR'
}
```

### Authentication & Authorization

#### JWT Token Structure
```typescript
interface JWTPayload {
  sub: string; // user_id
  email: string;
  role: 'user' | 'admin';
  iat: number;
  exp: number;
  aud: string;
  iss: string;
}
```

#### Row Level Security (RLS)
```sql
-- Users can only access their own data
CREATE POLICY user_own_data ON quiz_results
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY user_own_sessions ON quiz_sessions
  FOR ALL USING (auth.uid() = user_id);

-- Quiz questions are readable by all authenticated users
CREATE POLICY quiz_questions_read ON quiz_questions
  FOR SELECT USING (auth.role() = 'authenticated');
```

## Real-time Features

### Supabase Realtime Integration

#### Real-time Subscriptions
```typescript
// Quiz data updates
const quizSubscription = supabase
  .channel('quiz_updates')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'quiz_versions'
  }, (payload) => {
    // Notify clients of new quiz data
  })
  .subscribe();

// User progress updates
const progressSubscription = supabase
  .channel(`user_progress:${userId}`)
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'quiz_results',
    filter: `user_id=eq.${userId}`
  }, (payload) => {
    // Update progress in real-time
  })
  .subscribe();
```

## External Integrations

### OpenAI Integration

#### AI Quiz Generation
```typescript
interface OpenAIConfig {
  apiKey: string;
  model: 'gpt-4' | 'gpt-3.5-turbo';
  maxTokens: number;
  temperature: number;
}

const generateQuizPrompt = (category: string, difficulty: string) => `
Generate a ${difficulty} level quiz question about ${category} in Korean.
Return JSON format:
{
  "question": "문제 내용",
  "correct_answer": "정답",
  "options": ["선택지1", "선택지2", "선택지3", "선택지4"],
  "explanation": "해설"
}
`;
```

### File Storage

#### Audio File Management
```typescript
interface AudioFileConfig {
  bucket: 'quiz-audio';
  allowedFormats: ['mp3', 'wav', 'aac'];
  maxFileSize: 10 * 1024 * 1024; // 10MB
  cdnUrl: string;
}
```

## Security

### Data Protection

#### Encryption
- 데이터베이스: PostgreSQL 내장 암호화
- 전송: HTTPS/TLS 1.3
- 토큰: JWT with RS256 signing

#### Input Validation
```typescript
const quizQuestionSchema = {
  question: { type: 'string', minLength: 10, maxLength: 500 },
  correct_answer: { type: 'string', minLength: 1, maxLength: 200 },
  category: { type: 'string', enum: ['person', 'general', 'country', 'drama', 'music'] },
  difficulty: { type: 'string', enum: ['easy', 'medium', 'hard'] }
};
```

#### Rate Limiting
```typescript
const rateLimits = {
  '/api/v1/auth/*': { requests: 5, window: '15m' },
  '/api/v1/quiz/*': { requests: 100, window: '1h' },
  '/api/v1/sync/*': { requests: 50, window: '1h' },
  '/api/v1/ai/*': { requests: 10, window: '1h' }
};
```

## Performance Optimization

### Caching Strategy

#### Redis Caching
```typescript
interface CacheConfig {
  quiz_data: { ttl: 3600 }, // 1 hour
  user_stats: { ttl: 1800 }, // 30 minutes
  ai_responses: { ttl: 86400 }, // 24 hours
  quiz_versions: { ttl: 7200 } // 2 hours
}
```

#### Database Optimization
- Connection pooling: 최대 20개 연결
- Query optimization: EXPLAIN ANALYZE 사용
- Materialized views: 통계 데이터용
- Partitioning: quiz_results 테이블 월별 파티션

### CDN Integration
```typescript
interface CDNConfig {
  provider: 'Supabase Storage';
  regions: ['ap-northeast-1', 'us-west-1'];
  cacheHeaders: {
    'Cache-Control': 'public, max-age=31536000',
    'ETag': 'auto-generated'
  };
}
```

## Monitoring and Logging

### Health Checks
```typescript
interface HealthCheck {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  services: {
    database: { status: string; response_time: number };
    auth: { status: string; response_time: number };
    storage: { status: string; response_time: number };
    ai_service: { status: string; response_time: number };
  };
}
```

### Metrics Collection
```typescript
interface Metrics {
  api_requests_total: Counter;
  api_request_duration: Histogram;
  database_connections: Gauge;
  quiz_completions_total: Counter;
  ai_generations_total: Counter;
  error_rate: Gauge;
}
```

## Deployment Architecture

### Supabase Configuration
```typescript
interface SupabaseConfig {
  project_url: string;
  anon_key: string;
  service_role_key: string;
  database: {
    host: string;
    port: 5432;
    database: string;
    max_connections: 20;
  };
  auth: {
    site_url: string;
    redirect_urls: string[];
    jwt_expiry: 3600;
  };
}
```

### Environment Management
```bash
# Production
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
OPENAI_API_KEY=your-openai-key
ENVIRONMENT=production

# Development
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=local-anon-key
SUPABASE_SERVICE_ROLE_KEY=local-service-role-key
OPENAI_API_KEY=your-openai-key
ENVIRONMENT=development
```

## Testing Strategy

### Unit Testing
- Edge Functions 로직 테스트
- 데이터 검증 함수 테스트
- AI 응답 파싱 테스트

### Integration Testing
- API 엔드포인트 테스트
- 데이터베이스 연동 테스트
- 외부 서비스 연동 테스트

### Load Testing
```typescript
interface LoadTestConfig {
  concurrent_users: 100;
  test_duration: '10m';
  scenarios: {
    auth_flow: { weight: 20 };
    quiz_data_fetch: { weight: 40 };
    progress_sync: { weight: 30 };
    ai_generation: { weight: 10 };
  };
}
```

## Migration Strategy

### Database Migrations
```sql
-- Migration: 001_initial_schema.sql
-- Migration: 002_add_quiz_versions.sql
-- Migration: 003_add_indexes.sql
-- Migration: 004_add_rls_policies.sql
```

### Data Migration
```typescript
interface MigrationPlan {
  phase1: 'Setup Supabase project and basic schema';
  phase2: 'Migrate quiz data from existing sources';
  phase3: 'Setup authentication and user data';
  phase4: 'Configure real-time features';
  phase5: 'Deploy and test production environment';
}
```