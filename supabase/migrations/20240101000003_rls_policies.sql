-- Row Level Security (RLS) policies for data access control

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_versions ENABLE ROW LEVEL SECURITY;

-- Users table policies
-- Users can read and update their own profile
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Service role can manage all users (for admin functions)
CREATE POLICY "Service role can manage users" ON users
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Quiz questions policies
-- All authenticated users can read active quiz questions
CREATE POLICY "Authenticated users can read active quiz questions" ON quiz_questions
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active = true
  );

-- Only service role can manage quiz questions (admin functions)
CREATE POLICY "Service role can manage quiz questions" ON quiz_questions
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Quiz versions policies
-- All authenticated users can read quiz versions
CREATE POLICY "Authenticated users can read quiz versions" ON quiz_versions
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Only service role can manage quiz versions
CREATE POLICY "Service role can manage quiz versions" ON quiz_versions
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Quiz sessions policies
-- Users can only access their own quiz sessions
CREATE POLICY "Users can view own quiz sessions" ON quiz_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own quiz sessions" ON quiz_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own quiz sessions" ON quiz_sessions
  FOR UPDATE USING (auth.uid() = user_id);

-- Service role can access all sessions (for admin/analytics)
CREATE POLICY "Service role can manage all quiz sessions" ON quiz_sessions
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Quiz results policies
-- Users can only access their own quiz results
CREATE POLICY "Users can view own quiz results" ON quiz_results
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own quiz results" ON quiz_results
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own quiz results" ON quiz_results
  FOR UPDATE USING (auth.uid() = user_id);

-- Service role can access all results (for admin/analytics)
CREATE POLICY "Service role can manage all quiz results" ON quiz_results
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Additional security functions
-- Function to check if user owns a quiz session
CREATE OR REPLACE FUNCTION user_owns_session(session_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM quiz_sessions 
    WHERE id = session_uuid AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate quiz result ownership through session
CREATE OR REPLACE FUNCTION validate_quiz_result_ownership(session_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN user_owns_session(session_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced policy for quiz results that validates session ownership
DROP POLICY IF EXISTS "Users can insert own quiz results" ON quiz_results;
CREATE POLICY "Users can insert own quiz results" ON quiz_results
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND 
    validate_quiz_result_ownership(session_id)
  );