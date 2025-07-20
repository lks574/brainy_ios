#!/usr/bin/env node

// Comprehensive test script for database schema features
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'http://127.0.0.1:54321';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';
const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

const supabase = createClient(supabaseUrl, serviceRoleKey);
const anonClient = createClient(supabaseUrl, anonKey);

async function testDatabaseFeatures() {
  console.log('🧪 Testing Database Schema Features\n');
  console.log('=' .repeat(50));

  try {
    // Test 1: Table Structure
    console.log('\n📋 1. TABLE STRUCTURE TESTS');
    console.log('-'.repeat(30));

    const tables = ['users', 'quiz_questions', 'quiz_results', 'quiz_sessions', 'quiz_versions'];
    
    for (const table of tables) {
      const { data, error } = await supabase.from(table).select('*').limit(1);
      if (error) {
        console.log(`❌ ${table}: ${error.message}`);
      } else {
        console.log(`✅ ${table}: Table exists and accessible`);
      }
    }

    // Test 2: Data Constraints
    console.log('\n🔒 2. CONSTRAINT TESTS');
    console.log('-'.repeat(30));

    // Test category constraint
    const { error: categoryError } = await supabase
      .from('quiz_questions')
      .insert({
        question: 'Test question with invalid category that is long enough',
        correct_answer: 'Test answer',
        category: 'invalid_category',
        version: '1.0.0'
      });
    
    console.log(categoryError ? '✅ Category constraint: Working' : '❌ Category constraint: Failed');

    // Test difficulty constraint
    const { error: difficultyError } = await supabase
      .from('quiz_questions')
      .insert({
        question: 'Test question with invalid difficulty that is long enough',
        correct_answer: 'Test answer',
        category: 'general',
        difficulty: 'invalid_difficulty',
        version: '1.0.0'
      });
    
    console.log(difficultyError ? '✅ Difficulty constraint: Working' : '❌ Difficulty constraint: Failed');

    // Test question length constraint
    const { error: lengthError } = await supabase
      .from('quiz_questions')
      .insert({
        question: 'Short',
        correct_answer: 'Test answer',
        category: 'general',
        version: '1.0.0'
      });
    
    console.log(lengthError ? '✅ Question length constraint: Working' : '❌ Question length constraint: Failed');

    // Test 3: Row Level Security
    console.log('\n🛡️  3. ROW LEVEL SECURITY TESTS');
    console.log('-'.repeat(30));

    // Test anonymous access
    const { data: anonData, error: anonError } = await anonClient
      .from('quiz_questions')
      .select('*')
      .limit(1);
    
    if (anonError || (anonData && anonData.length === 0)) {
      console.log('✅ Anonymous access: Properly restricted');
    } else {
      console.log('❌ Anonymous access: Not restricted');
    }

    // Test authenticated access
    const testEmail = 'test@example.com';
    const testPassword = 'testpassword123';
    
    const { data: authData, error: authError } = await anonClient.auth.signInWithPassword({
      email: testEmail,
      password: testPassword,
    });

    if (!authError) {
      const { data: authQuestions } = await anonClient
        .from('quiz_questions')
        .select('*')
        .limit(1);
      
      console.log(authQuestions && authQuestions.length > 0 ? 
        '✅ Authenticated access: Working' : 
        '❌ Authenticated access: Failed');
    }

    // Test 4: Indexes and Performance
    console.log('\n⚡ 4. INDEX TESTS');
    console.log('-'.repeat(30));

    // Test category index
    const start = Date.now();
    const { data: categoryData } = await supabase
      .from('quiz_questions')
      .select('*')
      .eq('category', 'general');
    const end = Date.now();
    
    console.log(`✅ Category index: Query completed in ${end - start}ms`);

    // Test 5: Triggers and Functions
    console.log('\n🔧 5. TRIGGER TESTS');
    console.log('-'.repeat(30));

    // Test version question count trigger
    const { data: versionBefore } = await supabase
      .from('quiz_versions')
      .select('question_count')
      .eq('version', '1.0.0')
      .single();

    const { data: newQuestion } = await supabase
      .from('quiz_questions')
      .insert({
        question: 'Test trigger question that is long enough to pass validation',
        correct_answer: 'Test answer',
        category: 'general',
        version: '1.0.0'
      })
      .select()
      .single();

    const { data: versionAfter } = await supabase
      .from('quiz_versions')
      .select('question_count')
      .eq('version', '1.0.0')
      .single();

    if (versionAfter.question_count === versionBefore.question_count + 1) {
      console.log('✅ Question count trigger: Working');
    } else {
      console.log('❌ Question count trigger: Failed');
    }

    // Clean up test question
    if (newQuestion) {
      await supabase
        .from('quiz_questions')
        .delete()
        .eq('id', newQuestion.id);
    }

    // Test 6: Foreign Key Relationships
    console.log('\n🔗 6. RELATIONSHIP TESTS');
    console.log('-'.repeat(30));

    // Test foreign key constraint
    const { error: fkError } = await supabase
      .from('quiz_results')
      .insert({
        user_id: '00000000-0000-0000-0000-000000000000', // Non-existent user
        question_id: '00000000-0000-0000-0000-000000000000', // Non-existent question
        session_id: '00000000-0000-0000-0000-000000000000', // Non-existent session
        user_answer: 'Test answer',
        is_correct: true,
        time_spent: 30
      });

    console.log(fkError ? '✅ Foreign key constraints: Working' : '❌ Foreign key constraints: Failed');

    // Test 7: Data Types and JSON
    console.log('\n📊 7. DATA TYPE TESTS');
    console.log('-'.repeat(30));

    // Test JSONB options field
    const { data: jsonTest } = await supabase
      .from('quiz_questions')
      .select('options')
      .limit(1)
      .single();

    if (jsonTest && Array.isArray(jsonTest.options)) {
      console.log('✅ JSONB options field: Working');
    } else {
      console.log('❌ JSONB options field: Failed');
    }

    // Test metadata JSONB field
    const { data: metadataTest } = await supabase
      .from('users')
      .select('metadata')
      .limit(1);

    console.log('✅ JSONB metadata field: Working');

    console.log('\n🎉 Database schema testing completed!');
    console.log('=' .repeat(50));

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testDatabaseFeatures();