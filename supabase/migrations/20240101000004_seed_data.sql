-- Seed data for initial setup

-- Insert initial quiz version
INSERT INTO quiz_versions (version, description, is_current, question_count) 
VALUES ('1.0.0', 'Initial quiz data version', true, 0);

-- Insert sample quiz questions for testing
INSERT INTO quiz_questions (question, correct_answer, options, category, difficulty, type, version) VALUES
-- Person category questions
('다음 중 한국의 대통령이었던 사람은 누구일까요?', '김대중', 
 '["김대중", "김철수", "박영희", "이민수"]'::jsonb, 
 'person', 'easy', 'multiple_choice', '1.0.0'),

('조선시대 세종대왕이 창제한 것은 무엇인가요?', '한글', 
 '["한글", "한자", "영어", "일본어"]'::jsonb, 
 'person', 'easy', 'multiple_choice', '1.0.0'),

-- General category questions
('대한민국의 수도는 어디인가요?', '서울', 
 '["서울", "부산", "대구", "인천"]'::jsonb, 
 'general', 'easy', 'multiple_choice', '1.0.0'),

('태극기의 중앙에 있는 것은 무엇인가요?', '태극', 
 '["태극", "무궁화", "한글", "거북선"]'::jsonb, 
 'general', 'easy', 'multiple_choice', '1.0.0'),

-- Country category questions
('다음 중 유럽에 위치한 국가는 어디인가요?', '프랑스', 
 '["프랑스", "일본", "중국", "태국"]'::jsonb, 
 'country', 'easy', 'multiple_choice', '1.0.0'),

('미국의 수도는 어디인가요?', '워싱턴 D.C.', 
 '["워싱턴 D.C.", "뉴욕", "로스앤젤레스", "시카고"]'::jsonb, 
 'country', 'easy', 'multiple_choice', '1.0.0'),

-- Drama category questions
('다음 중 한국 드라마는 무엇인가요?', '대장금', 
 '["대장금", "원피스", "나루토", "드래곤볼"]'::jsonb, 
 'drama', 'medium', 'multiple_choice', '1.0.0'),

-- Music category questions
('다음 중 한국 출신 가수는 누구인가요?', 'BTS', 
 '["BTS", "비틀즈", "마이클 잭슨", "엘비스 프레슬리"]'::jsonb, 
 'music', 'easy', 'multiple_choice', '1.0.0');

-- Update question count in version
UPDATE quiz_versions 
SET question_count = (SELECT COUNT(*) FROM quiz_questions WHERE version = '1.0.0')
WHERE version = '1.0.0';

-- Create a function to automatically update question count when questions are added/removed
CREATE OR REPLACE FUNCTION update_version_question_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE quiz_versions 
    SET question_count = question_count + 1 
    WHERE version = NEW.version;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE quiz_versions 
    SET question_count = question_count - 1 
    WHERE version = OLD.version;
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    -- If version changed, update both old and new versions
    IF OLD.version != NEW.version THEN
      UPDATE quiz_versions 
      SET question_count = question_count - 1 
      WHERE version = OLD.version;
      
      UPDATE quiz_versions 
      SET question_count = question_count + 1 
      WHERE version = NEW.version;
    END IF;
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to maintain question count
CREATE TRIGGER trigger_update_version_question_count
  AFTER INSERT OR UPDATE OR DELETE ON quiz_questions
  FOR EACH ROW EXECUTE FUNCTION update_version_question_count();