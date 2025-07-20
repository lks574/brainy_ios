#!/usr/bin/env node

/**
 * Test script for authentication system
 * Tests email/password auth, OAuth simulation, and JWT token verification
 */

const { createClient } = require('@supabase/supabase-js');

// Configuration
const SUPABASE_URL = process.env.SUPABASE_URL || 'http://localhost:54321';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const AUTH_FUNCTION_URL = `${SUPABASE_URL}/functions/v1/auth`;

// Test data
const testUser = {
  email: 'test@example.com',
  password: 'testpassword123',
  display_name: 'Test User'
};

async function makeRequest(endpoint, method = 'GET', body = null, headers = {}) {
  const url = `${AUTH_FUNCTION_URL}/${endpoint}`;
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
      ...headers
    }
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  try {
    const response = await fetch(url, options);
    const data = await response.json();
    return { status: response.status, data };
  } catch (error) {
    return { status: 500, error: error.message };
  }
}

async function testSignup() {
  console.log('\n🔐 Testing user signup...');
  
  const result = await makeRequest('signup', 'POST', testUser);
  
  if (result.status === 200 && result.data.success) {
    console.log('✅ Signup successful');
    console.log(`   User ID: ${result.data.data.user.id}`);
    console.log(`   Email: ${result.data.data.user.email}`);
    console.log(`   Display Name: ${result.data.data.user.display_name}`);
    return result.data.data;
  } else {
    console.log('❌ Signup failed');
    console.log(`   Status: ${result.status}`);
    console.log(`   Error: ${result.data?.error?.message || result.error}`);
    return null;
  }
}

async function testSignin() {
  console.log('\n🔑 Testing user signin...');
  
  const result = await makeRequest('signin', 'POST', {
    email: testUser.email,
    password: testUser.password
  });
  
  if (result.status === 200 && result.data.success) {
    console.log('✅ Signin successful');
    console.log(`   Access Token: ${result.data.data.access_token.substring(0, 20)}...`);
    console.log(`   Expires In: ${result.data.data.expires_in} seconds`);
    return result.data.data;
  } else {
    console.log('❌ Signin failed');
    console.log(`   Status: ${result.status}`);
    console.log(`   Error: ${result.data?.error?.message || result.error}`);
    return null;
  }
}

async function testGetUser(accessToken) {
  console.log('\n👤 Testing get user info...');
  
  const result = await makeRequest('user', 'GET', null, {
    'Authorization': `Bearer ${accessToken}`
  });
  
  if (result.status === 200 && result.data.success) {
    console.log('✅ Get user successful');
    console.log(`   User ID: ${result.data.data.id}`);
    console.log(`   Email: ${result.data.data.email}`);
    console.log(`   Display Name: ${result.data.data.display_name}`);
    console.log(`   Auth Provider: ${result.data.data.auth_provider}`);
    return result.data.data;
  } else {
    console.log('❌ Get user failed');
    console.log(`   Status: ${result.status}`);
    console.log(`   Error: ${result.data?.error?.message || result.error}`);
    return null;
  }
}

async function testUpdateUser(accessToken) {
  console.log('\n✏️ Testing update user...');
  
  const result = await makeRequest('user', 'PUT', {
    display_name: 'Updated Test User'
  }, {
    'Authorization': `Bearer ${accessToken}`
  });
  
  if (result.status === 200 && result.data.success) {
    console.log('✅ Update user successful');
    console.log(`   New Display Name: ${result.data.data.display_name}`);
    return result.data.data;
  } else {
    console.log('❌ Update user failed');
    console.log(`   Status: ${result.status}`);
    console.log(`   Error: ${result.data?.error?.message || result.error}`);
    return null;
  }
}

async function testRefreshToken(refreshToken) {
  console.log('\n🔄 Testing token refresh...');
  
  const result = await makeRequest('refresh', 'POST', {
    refresh_token: refreshToken
  });
  
  if (result.status === 200 && result.data.success) {
    console.log('✅ Token refresh successful');
    console.log(`   New Access Token: ${result.data.data.access_token.substring(0, 20)}...`);
    return result.data.data;
  } else {
    console.log('❌ Token refresh failed');
    console.log(`   Status: ${result.status}`);
    console.log(`   Error: ${result.data?.error?.message || result.error}`);
    return null;
  }
}

async function testSignout(accessToken) {
  console.log('\n🚪 Testing user signout...');
  
  const result = await makeRequest('signout', 'POST', null, {
    'Authorization': `Bearer ${accessToken}`
  });
  
  if (result.status === 200 && result.data.success) {
    console.log('✅ Signout successful');
    return true;
  } else {
    console.log('❌ Signout failed');
    console.log(`   Status: ${result.status}`);
    console.log(`   Error: ${result.data?.error?.message || result.error}`);
    return false;
  }
}

async function testRateLimit() {
  console.log('\n⏱️ Testing rate limiting...');
  
  const promises = [];
  for (let i = 0; i < 7; i++) { // Exceed the limit of 5 requests
    promises.push(makeRequest('signin', 'POST', {
      email: 'invalid@example.com',
      password: 'invalid'
    }));
  }
  
  const results = await Promise.all(promises);
  const rateLimitedRequests = results.filter(r => r.status === 429);
  
  if (rateLimitedRequests.length > 0) {
    console.log('✅ Rate limiting working');
    console.log(`   ${rateLimitedRequests.length} requests were rate limited`);
    return true;
  } else {
    console.log('❌ Rate limiting not working');
    return false;
  }
}

async function testValidation() {
  console.log('\n✅ Testing input validation...');
  
  // Test invalid email
  const invalidEmailResult = await makeRequest('signup', 'POST', {
    email: 'invalid-email',
    password: 'password123'
  });
  
  if (invalidEmailResult.status === 400) {
    console.log('✅ Email validation working');
  } else {
    console.log('❌ Email validation not working');
  }
  
  // Test short password
  const shortPasswordResult = await makeRequest('signup', 'POST', {
    email: 'test2@example.com',
    password: '123'
  });
  
  if (shortPasswordResult.status === 400) {
    console.log('✅ Password validation working');
  } else {
    console.log('❌ Password validation not working');
  }
}

async function runTests() {
  console.log('🚀 Starting Authentication System Tests');
  console.log(`📍 Testing against: ${AUTH_FUNCTION_URL}`);
  
  try {
    // Test validation
    await testValidation();
    
    // Test rate limiting
    await testRateLimit();
    
    // Wait a bit for rate limit to reset
    console.log('\n⏳ Waiting for rate limit to reset...');
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Test main auth flow
    const signupResult = await testSignup();
    if (!signupResult) return;
    
    const signinResult = await testSignin();
    if (!signinResult) return;
    
    const getUserResult = await testGetUser(signinResult.access_token);
    if (!getUserResult) return;
    
    const updateUserResult = await testUpdateUser(signinResult.access_token);
    if (!updateUserResult) return;
    
    const refreshResult = await testRefreshToken(signinResult.refresh_token);
    if (!refreshResult) return;
    
    const signoutResult = await testSignout(signinResult.access_token);
    
    console.log('\n🎉 All authentication tests completed!');
    
  } catch (error) {
    console.error('\n💥 Test suite failed:', error);
  }
}

// Run tests if this script is executed directly
if (require.main === module) {
  runTests();
}

module.exports = {
  runTests,
  testSignup,
  testSignin,
  testGetUser,
  testUpdateUser,
  testRefreshToken,
  testSignout
};