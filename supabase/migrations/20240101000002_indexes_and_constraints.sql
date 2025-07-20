-- Database indexes and additional constraints for performance optimization

-- Performance indexes for quiz_questions
CREATE INDEX idx_quiz_questions_category ON quiz_questions(category);
CREATE INDEX idx_quiz_questions_active ON quiz_questions(is_active);
CREATE INDEX idx_quiz_questions_version ON quiz_questions(version);
CREATE INDEX idx_quiz_questions_difficulty ON quiz_questions(difficulty);
CREATE INDEX idx_quiz_questions_type ON quiz_questions(type);

-- Composite indexes for quiz_questions
CREATE INDEX idx_quiz_questions_category_type ON quiz_questions(category, type);
CREATE INDEX idx_quiz_questions_category_difficulty ON quiz_questions(category, difficulty);
CREATE INDEX idx_quiz_questions_active_category ON quiz_questions(is_active, category);

-- Performance indexes for quiz_results
CREATE INDEX idx_quiz_results_user_id ON quiz_results(user_id);
CREATE INDEX idx_quiz_results_question_id ON quiz_results(question_id);
CREATE INDEX idx_quiz_results_session_id ON quiz_results(session_id);
CREATE INDEX idx_quiz_results_completed_at ON quiz_results(completed_at);
CREATE INDEX idx_quiz_results_is_correct ON quiz_results(is_correct);

-- Composite indexes for quiz_results
CREATE INDEX idx_quiz_results_user_session ON quiz_results(user_id, session_id);
CREATE INDEX idx_quiz_results_user_completed ON quiz_results(user_id, completed_at);

-- Performance indexes for quiz_sessions
CREATE INDEX idx_quiz_sessions_user_id ON quiz_sessions(user_id);
CREATE INDEX idx_quiz_sessions_category ON quiz_sessions(category);
CREATE INDEX idx_quiz_sessions_mode ON quiz_sessions(mode);
CREATE INDEX idx_quiz_sessions_started_at ON quiz_sessions(started_at);
CREATE INDEX idx_quiz_sessions_completed_at ON quiz_sessions(completed_at);

-- Composite indexes for quiz_sessions
CREATE INDEX idx_quiz_sessions_user_category ON quiz_sessions(user_id, category);
CREATE INDEX idx_quiz_sessions_user_completed ON quiz_sessions(user_id, completed_at);

-- Performance indexes for users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_auth_provider ON users(auth_provider);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_last_sync_at ON users(last_sync_at);

-- Performance indexes for quiz_versions
CREATE INDEX idx_quiz_versions_is_current ON quiz_versions(is_current);
CREATE INDEX idx_quiz_versions_created_at ON quiz_versions(created_at);

-- Additional constraints for data integrity
ALTER TABLE users ADD CONSTRAINT chk_email_format 
  CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

ALTER TABLE users ADD CONSTRAINT chk_auth_provider 
  CHECK (auth_provider IN ('email', 'google', 'apple'));

ALTER TABLE quiz_questions ADD CONSTRAINT chk_question_length 
  CHECK (char_length(question) >= 10 AND char_length(question) <= 1000);

ALTER TABLE quiz_questions ADD CONSTRAINT chk_correct_answer_length 
  CHECK (char_length(correct_answer) >= 1 AND char_length(correct_answer) <= 500);

ALTER TABLE quiz_sessions ADD CONSTRAINT chk_total_questions_positive 
  CHECK (total_questions > 0);

ALTER TABLE quiz_sessions ADD CONSTRAINT chk_correct_answers_valid 
  CHECK (correct_answers >= 0 AND correct_answers <= total_questions);

ALTER TABLE quiz_sessions ADD CONSTRAINT chk_total_time_positive 
  CHECK (total_time >= 0);

ALTER TABLE quiz_results ADD CONSTRAINT chk_time_spent_positive 
  CHECK (time_spent >= 0);

-- Ensure completed_at is after started_at for sessions
ALTER TABLE quiz_sessions ADD CONSTRAINT chk_session_time_order 
  CHECK (completed_at IS NULL OR completed_at >= started_at);