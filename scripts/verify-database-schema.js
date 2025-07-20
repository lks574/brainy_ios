#!/usr/bin/env node

// Simple script to verify database schema
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'http://127.0.0.1:54321';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';
const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

const supabase = createClient(supabaseUrl, serviceRoleKey);
const anonClient = createClient(supabaseUrl, anonKey);

async function verifySchema() {
  console.log('🔍 Verifying database schema...\n');

  try {
    // Test 1: Check if all tables exist and have data
    console.log('1. Checking tables...');
    
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('*')
      .limit(1);
    
    if (usersError) {
      console.log('❌ Users table error:', usersError.message);
    } else {
      console.log('✅ Users table exists');
    }

    const { data: questions, error: questionsError } = await supabase
      .from('quiz_questions')
      .select('*')
      .limit(5);
    
    if (questionsError) {
      console.log('❌ Quiz questions table error:', questionsError.message);
    } else {
      console.log(`✅ Quiz questions table exists with ${questions.length} sample questions`);
    }

    const { data: sessions, error: sessionsError } = await supabase
      .from('quiz_sessions')
      .select('*')
      .limit(1);
    
    if (sessionsError) {
      console.log('❌ Quiz sessions table error:', sessionsError.message);
    } else {
      console.log('✅ Quiz sessions table exists');
    }

    const { data: results, error: resultsError } = await supabase
      .from('quiz_results')
      .select('*')
      .limit(1);
    
    if (resultsError) {
      console.log('❌ Quiz results table error:', resultsError.message);
    } else {
      console.log('✅ Quiz results table exists');
    }

    const { data: versions, error: versionsError } = await supabase
      .from('quiz_versions')
      .select('*');
    
    if (versionsError) {
      console.log('❌ Quiz versions table error:', versionsError.message);
    } else {
      console.log(`✅ Quiz versions table exists with ${versions.length} versions`);
      if (versions.length > 0) {
        console.log(`   Current version: ${versions.find(v => v.is_current)?.version || 'None'}`);
      }
    }

    // Test 2: Check constraints and indexes
    console.log('\n2. Testing constraints...');
    
    // Test category constraint
    const { data: insertData, error: insertError } = await supabase
      .from('quiz_questions')
      .insert({
        question: 'Test question with invalid category that is long enough',
        correct_answer: 'Test answer',
        category: 'invalid_category',
        version: '1.0.0'
      });
    
    if (insertError) {
      console.log('✅ Category constraint working:', insertError.message);
    } else {
      console.log('❌ Category constraint not working - invalid data was inserted');
    }

    // Test 3: Check RLS policies
    console.log('\n3. Checking RLS policies...');
    
    const { data: anonQuestions, error: anonError } = await anonClient
      .from('quiz_questions')
      .select('*')
      .limit(1);
    
    if (anonError) {
      console.log('✅ RLS working - anonymous users cannot access questions:', anonError.message);
    } else if (anonQuestions && anonQuestions.length === 0) {
      console.log('✅ RLS working - anonymous users get empty results');
    } else {
      console.log('❌ RLS not working - anonymous users can access questions');
    }
    
    // Test authenticated access
    console.log('\n4. Testing authenticated access...');
    
    // Create a test user and sign in
    const testEmail = 'test@example.com';
    const testPassword = 'testpassword123';
    
    const { data: signUpData, error: signUpError } = await anonClient.auth.signUp({
      email: testEmail,
      password: testPassword,
    });
    
    if (signUpError && !signUpError.message.includes('already registered')) {
      console.log('⚠️  Could not create test user:', signUpError.message);
    } else {
      console.log('✅ Test user created or already exists');
      
      // Try to sign in
      const { data: signInData, error: signInError } = await anonClient.auth.signInWithPassword({
        email: testEmail,
        password: testPassword,
      });
      
      if (signInError) {
        console.log('⚠️  Could not sign in test user:', signInError.message);
      } else {
        console.log('✅ Test user signed in successfully');
        
        // Test authenticated access to quiz questions
        const { data: authQuestions, error: authError } = await anonClient
          .from('quiz_questions')
          .select('*')
          .limit(1);
        
        if (authError) {
          console.log('❌ Authenticated user cannot access questions:', authError.message);
        } else {
          console.log('✅ Authenticated user can access questions');
        }
      }
    }

    console.log('\n🎉 Database schema verification completed!');

  } catch (error) {
    console.error('❌ Verification failed:', error.message);
  }
}

verifySchema();