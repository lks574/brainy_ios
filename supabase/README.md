# Brainy Backend API - Database Schema

This document describes the implemented database schema for the Brainy Backend API.

## Overview

The database schema has been successfully implemented with the following components:

- ✅ **Core Tables**: All 5 required tables created
- ✅ **Indexes**: Performance indexes implemented
- ✅ **Constraints**: Data validation constraints added
- ✅ **Row Level Security**: RLS policies implemented
- ✅ **Triggers**: Automated functions for data maintenance
- ✅ **Seed Data**: Sample data for testing

## Tables Implemented

### 1. users
- **Purpose**: Store user account information
- **Key Features**: 
  - UUID primary key
  - Email uniqueness constraint
  - Support for multiple auth providers (email, google, apple)
  - Metadata JSONB field for extensibility
  - Activity tracking (last_sync_at, is_active)

### 2. quiz_questions
- **Purpose**: Store quiz questions and answers
- **Key Features**:
  - Support for multiple question types (multiple_choice, short_answer, true_false)
  - Category-based organization (person, general, country, drama, music)
  - Difficulty levels (easy, medium, hard)
  - Version tracking for data updates
  - JSONB options field for multiple choice answers
  - Audio URL support for voice mode
  - Automatic updated_at timestamp

### 3. quiz_sessions
- **Purpose**: Track user quiz sessions
- **Key Features**:
  - Links to users table
  - Session metadata (category, mode, timing)
  - Progress tracking (total_questions, correct_answers, total_time)
  - Support for different quiz modes (practice, timed, challenge, ai_generated)
  - JSONB metadata field for extensibility

### 4. quiz_results
- **Purpose**: Store individual question results
- **Key Features**:
  - Links to users, questions, and sessions
  - Answer tracking (user_answer, is_correct)
  - Time tracking per question
  - Supports detailed analytics

### 5. quiz_versions
- **Purpose**: Track quiz data versions for synchronization
- **Key Features**:
  - Version string tracking
  - Automatic question count maintenance
  - Current version flagging
  - Description field for release notes

## Constraints Implemented

### Data Validation
- **Email format validation**: Ensures valid email addresses
- **Category constraints**: Restricts to valid categories
- **Difficulty constraints**: Restricts to valid difficulty levels
- **Question type constraints**: Restricts to valid question types
- **Quiz mode constraints**: Restricts to valid quiz modes
- **Length constraints**: Ensures minimum/maximum lengths for text fields
- **Positive number constraints**: Ensures non-negative values for counts and times
- **Time order constraints**: Ensures completed_at is after started_at

### Referential Integrity
- **Foreign key constraints**: Maintain relationships between tables
- **Cascade deletes**: Properly handle user account deletion
- **Unique constraints**: Prevent duplicate versions and emails

## Indexes Implemented

### Performance Indexes
- **Single column indexes**: On frequently queried fields
- **Composite indexes**: For multi-column queries
- **Partial indexes**: For conditional queries (e.g., active questions only)

### Key Indexes
- `quiz_questions`: category, difficulty, type, is_active, version
- `quiz_results`: user_id, question_id, session_id, completed_at
- `quiz_sessions`: user_id, category, mode, started_at, completed_at
- `users`: email, auth_provider, is_active, created_at
- `quiz_versions`: is_current, created_at

## Row Level Security (RLS)

### Security Policies
- **Users**: Can only access their own profile data
- **Quiz Questions**: Authenticated users can read active questions
- **Quiz Sessions**: Users can only access their own sessions
- **Quiz Results**: Users can only access their own results
- **Quiz Versions**: All authenticated users can read versions
- **Service Role**: Full access for admin functions

### Authentication Integration
- Uses Supabase Auth for user identification
- Policies check `auth.uid()` for user ownership
- Service role bypasses RLS for admin operations

## Triggers and Functions

### Automated Maintenance
- **Question Count Trigger**: Automatically updates question count in quiz_versions
- **Updated At Trigger**: Maintains updated_at timestamps
- **Ownership Validation**: Functions to validate data ownership

### Custom Functions
- `update_updated_at_column()`: Updates timestamp on row changes
- `update_version_question_count()`: Maintains question counts
- `user_owns_session()`: Validates session ownership
- `validate_quiz_result_ownership()`: Validates result ownership through session

## Migration Files

The schema is implemented through 4 migration files:

1. **20240101000001_initial_schema.sql**: Core table creation
2. **20240101000002_indexes_and_constraints.sql**: Performance and validation
3. **20240101000003_rls_policies.sql**: Security policies
4. **20240101000004_seed_data.sql**: Sample data and triggers

## Testing

### Verification Scripts
- `scripts/verify-database-schema.js`: Basic schema verification
- `scripts/test-database-features.js`: Comprehensive feature testing

### Test Coverage
- ✅ Table structure and accessibility
- ✅ Data constraints and validation
- ✅ Row Level Security policies
- ✅ Index performance
- ✅ Trigger functionality
- ✅ Foreign key relationships
- ✅ JSONB data types

## Usage

### Local Development
```bash
# Start Supabase
npm run dev

# Reset database with migrations
npm run reset

# Run tests
node scripts/test-database-features.js
```

### Database Connection
- **Local URL**: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`
- **API URL**: `http://127.0.0.1:54321`
- **Studio URL**: `http://127.0.0.1:54323`

## Requirements Satisfied

This implementation satisfies the following requirements from the specification:

- **Requirement 3.1**: User progress synchronization data storage
- **Requirement 3.2**: Progress data download and conflict resolution
- **Requirement 8.5**: Security measures and data protection

The database schema provides a solid foundation for the Brainy Backend API, supporting all planned features including user authentication, quiz data management, progress synchronization, and real-time updates.