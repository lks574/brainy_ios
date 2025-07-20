-- Initial database schema for Brainy Backend API
-- Creates core tables: users, quiz_questions, quiz_results, quiz_sessions, quiz_versions

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE,
  display_name VARCHAR(100) NOT NULL,
  auth_provider VARCHAR(20) NOT NULL DEFAULT 'email',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_sync_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Quiz versions table
CREATE TABLE quiz_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  question_count INTEGER DEFAULT 0,
  is_current BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Quiz questions table
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
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT fk_quiz_questions_version FOREIGN KEY (version) REFERENCES quiz_versions(version)
);

-- Quiz sessions table
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
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Quiz results table
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

-- Add constraints
ALTER TABLE quiz_questions ADD CONSTRAINT chk_category 
  CHECK (category IN ('person', 'general', 'country', 'drama', 'music'));

ALTER TABLE quiz_questions ADD CONSTRAINT chk_difficulty 
  CHECK (difficulty IN ('easy', 'medium', 'hard'));

ALTER TABLE quiz_questions ADD CONSTRAINT chk_type 
  CHECK (type IN ('multiple_choice', 'short_answer', 'true_false'));

ALTER TABLE quiz_sessions ADD CONSTRAINT chk_mode 
  CHECK (mode IN ('practice', 'timed', 'challenge', 'ai_generated'));

-- Ensure only one current version exists
CREATE UNIQUE INDEX idx_quiz_versions_current ON quiz_versions(is_current) WHERE is_current = true;

-- Add updated_at trigger for quiz_questions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_quiz_questions_updated_at 
  BEFORE UPDATE ON quiz_questions 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();