import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'
import { validateRequest } from '../_shared/validation.ts'
import { createErrorResponse, createSuccessResponse } from '../_shared/response.ts'
import { withRateLimit, rateLimitConfigs } from '../_shared/rate-limit.ts'

interface AuthRequest {
  email: string
  password: string
  provider?: 'email' | 'google' | 'apple'
  token?: string
  display_name?: string
}

interface AuthResponse {
  access_token: string
  refresh_token: string
  expires_in: number
  user: {
    id: string
    email: string
    display_name: string
    auth_provider: string
    created_at: string
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const url = new URL(req.url)
    const path = url.pathname.split('/').pop()

    switch (req.method) {
      case 'POST':
        if (path === 'signup') {
          return await handleSignup(req, supabaseClient)
        } else if (path === 'signin') {
          return await handleSignin(req, supabaseClient)
        } else if (path === 'signout') {
          return await handleSignout(req, supabaseClient)
        } else if (path === 'oauth') {
          return await handleOAuth(req, supabaseClient)
        } else if (path === 'refresh') {
          return await handleRefreshToken(req, supabaseClient)
        }
        break
      
      case 'GET':
        if (path === 'user') {
          return await handleGetUser(req, supabaseClient)
        }
        break
      
      case 'PUT':
        if (path === 'user') {
          return await handleUpdateUser(req, supabaseClient)
        }
        break
    }

    return createErrorResponse('RESOURCE_NOT_FOUND', 'Endpoint not found', 404)

  } catch (error) {
    console.error('Auth function error:', error)
    return createErrorResponse('INTERNAL_SERVER_ERROR', 'Internal server error', 500)
  }
})

async function handleSignup(req: Request, supabaseClient: any) {
  const body = await req.json() as AuthRequest
  
  // Validate request
  const validation = validateRequest(body, {
    email: { type: 'string', required: true, format: 'email' },
    password: { type: 'string', required: true, minLength: 6 },
    display_name: { type: 'string', required: false, maxLength: 100 }
  })
  
  if (!validation.valid) {
    return createErrorResponse('VALIDATION_ERROR', validation.errors.join(', '), 400)
  }

  try {
    // Create user with Supabase Auth
    const { data: authData, error: authError } = await supabaseClient.auth.signUp({
      email: body.email,
      password: body.password,
      options: {
        data: {
          display_name: body.display_name || body.email.split('@')[0]
        }
      }
    })

    if (authError) {
      return createErrorResponse('AUTHENTICATION_FAILED', authError.message, 400)
    }

    if (!authData.user) {
      return createErrorResponse('AUTHENTICATION_FAILED', 'Failed to create user', 400)
    }

    // Insert user profile data using service role to bypass RLS
    const { error: profileError } = await supabaseClient
      .from('users')
      .insert({
        id: authData.user.id,
        email: authData.user.email,
        display_name: body.display_name || authData.user.email?.split('@')[0],
        auth_provider: 'email'
      })

    if (profileError) {
      console.error('Profile creation error:', profileError)
      // Continue even if profile creation fails - user can still authenticate
    }

    const response: AuthResponse = {
      access_token: authData.session?.access_token || '',
      refresh_token: authData.session?.refresh_token || '',
      expires_in: authData.session?.expires_in || 3600,
      user: {
        id: authData.user.id,
        email: authData.user.email || '',
        display_name: body.display_name || authData.user.email?.split('@')[0] || '',
        auth_provider: 'email',
        created_at: authData.user.created_at
      }
    }

    return createSuccessResponse(response)

  } catch (error) {
    console.error('Signup error:', error)
    return createErrorResponse('INTERNAL_SERVER_ERROR', 'Failed to create account', 500)
  }
}

async function handleSignin(req: Request, supabaseClient: any) {
  const body = await req.json() as AuthRequest
  
  // Validate request
  const validation = validateRequest(body, {
    email: { type: 'string', required: true, format: 'email' },
    password: { type: 'string', required: true }
  })
  
  if (!validation.valid) {
    return createErrorResponse('VALIDATION_ERROR', validation.errors.join(', '), 400)
  }

  try {
    const { data: authData, error: authError } = await supabaseClient.auth.signInWithPassword({
      email: body.email,
      password: body.password
    })

    if (authError) {
      return createErrorResponse('AUTHENTICATION_FAILED', authError.message, 401)
    }

    if (!authData.user || !authData.session) {
      return createErrorResponse('AUTHENTICATION_FAILED', 'Invalid credentials', 401)
    }

    // Get user profile
    const { data: profile } = await supabaseClient
      .from('users')
      .select('*')
      .eq('id', authData.user.id)
      .single()

    const response: AuthResponse = {
      access_token: authData.session.access_token,
      refresh_token: authData.session.refresh_token,
      expires_in: authData.session.expires_in,
      user: {
        id: authData.user.id,
        email: authData.user.email || '',
        display_name: profile?.display_name || authData.user.email?.split('@')[0] || '',
        auth_provider: profile?.auth_provider || 'email',
        created_at: authData.user.created_at
      }
    }

    return createSuccessResponse(response)

  } catch (error) {
    console.error('Signin error:', error)
    return createErrorResponse('INTERNAL_SERVER_ERROR', 'Failed to sign in', 500)
  }
}

async function handleSignout(req: Request, supabaseClient: any) {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return createErrorResponse('AUTHENTICATION_FAILED', 'Missing authorization header', 401)
  }

  const token = authHeader.replace('Bearer ', '')

  try {
    const { error } = await supabaseClient.auth.signOut(token)
    
    if (error) {
      return createErrorResponse('AUTHENTICATION_FAILED', error.message, 400)
    }

    return createSuccessResponse({ message: 'Successfully signed out' })

  } catch (error) {
    console.error('Signout error:', error)
    return createErrorResponse('INTERNAL_SERVER_ERROR', 'Failed to sign out', 500)
  }
}

async function handleOAuth(req: Request, supabaseClient: any) {
  const body = await req.json() as AuthRequest
  
  // Validate request
  const validation = validateRequest(body, {
    provider: { type: 'string', required: true, enum: ['google', 'apple'] },
    token: { type: 'string', required: true }
  })
  
  if (!validation.valid) {
    return createErrorResponse('VALIDATION_ERROR', validation.errors.join(', '), 400)
  }

  try {
    let authData
    let authError

    if (body.provider === 'google') {
      // Handle Google OAuth
      const response = await fetch(`https://www.googleapis.com/oauth2/v1/userinfo?access_token=${body.token}`)
      const googleUser = await response.json()
      
      if (!googleUser.email) {
        return createErrorResponse('AUTHENTICATION_FAILED', 'Invalid Google token', 401)
      }

      // Sign in or create user with Google
      const { data, error } = await supabaseClient.auth.signInWithIdToken({
        provider: 'google',
        token: body.token
      })
      
      authData = data
      authError = error

    } else if (body.provider === 'apple') {
      // Handle Apple Sign-in
      const { data, error } = await supabaseClient.auth.signInWithIdToken({
        provider: 'apple',
        token: body.token
      })
      
      authData = data
      authError = error
    }

    if (authError) {
      return createErrorResponse('AUTHENTICATION_FAILED', authError.message, 401)
    }

    if (!authData?.user || !authData?.session) {
      return createErrorResponse('AUTHENTICATION_FAILED', 'OAuth authentication failed', 401)
    }

    // Upsert user profile using service role to bypass RLS
    const { error: profileError } = await supabaseClient
      .from('users')
      .upsert({
        id: authData.user.id,
        email: authData.user.email,
        display_name: authData.user.user_metadata?.full_name || authData.user.email?.split('@')[0],
        auth_provider: body.provider
      }, {
        onConflict: 'id'
      })

    if (profileError) {
      console.error('Profile upsert error:', profileError)
    }

    const response: AuthResponse = {
      access_token: authData.session.access_token,
      refresh_token: authData.session.refresh_token,
      expires_in: authData.session.expires_in,
      user: {
        id: authData.user.id,
        email: authData.user.email || '',
        display_name: authData.user.user_metadata?.full_name || authData.user.email?.split('@')[0] || '',
        auth_provider: body.provider || 'email',
        created_at: authData.user.created_at
      }
    }

    return createSuccessResponse(response)

  } catch (error) {
    console.error('OAuth error:', error)
    return createErrorResponse('INTERNAL_SERVER_ERROR', 'OAuth authentication failed', 500)
  }
}

async function handleGetUser(req: Request, supabaseClient: any) {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return createErrorResponse('AUTHENTICATION_FAILED', 'Missing authorization header', 401)
  }

  const token = authHeader.replace('Bearer ', '')

  try {
    const { data: { user }, error } = await supabaseClient.auth.getUser(token)
    
    if (error || !user) {
      return createErrorResponse('AUTHENTICATION_FAILED', 'Invalid token', 401)
    }

    // Get user profile
    const { data: profile } = await supabaseClient
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single()

    const response = {
      id: user.id,
      email: user.email || '',
      display_name: profile?.display_name || user.email?.split('@')[0] || '',
      auth_provider: profile?.auth_provider || 'email',
      created_at: user.created_at,
      last_sync_at: profile?.last_sync_at
    }

    return createSuccessResponse(response)

  } catch (error) {
    console.error('Get user error:', error)
    return createErrorResponse('INTERNAL_SERVER_ERROR', 'Failed to get user', 500)
  }
}

async function handleUpdateUser(req: Request, supabaseClient: any) {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return createErrorResponse('AUTHENTICATION_FAILED', 'Missing authorization header', 401)
  }

  const token = authHeader.replace('Bearer ', '')
  const body = await req.json()

  try {
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
    
    if (authError || !user) {
      return createErrorResponse('AUTHENTICATION_FAILED', 'Invalid token', 401)
    }

    // Validate request
    const validation = validateRequest(body, {
      display_name: { type: 'string', required: false, maxLength: 100 },
      email: { type: 'string', required: false, format: 'email' }
    })
    
    if (!validation.valid) {
      return createErrorResponse('VALIDATION_ERROR', validation.errors.join(', '), 400)
    }

    // Update user profile
    const updateData: any = {}
    if (body.display_name) updateData.display_name = body.display_name
    if (body.email) updateData.email = body.email

    if (Object.keys(updateData).length === 0) {
      return createErrorResponse('VALIDATION_ERROR', 'No fields to update', 400)
    }

    const { data: profile, error: updateError } = await supabaseClient
      .from('users')
      .update(updateData)
      .eq('id', user.id)
      .select()
      .maybeSingle()

    if (updateError) {
      return createErrorResponse('INTERNAL_SERVER_ERROR', updateError.message, 500)
    }

    return createSuccessResponse(profile)

  } catch (error) {
    console.error('Update user error:', error)
    return createErrorResponse('INTERNAL_SERVER_ERROR', 'Failed to update user', 500)
  }
}

async function handleRefreshToken(req: Request, supabaseClient: any) {
  const body = await req.json()
  
  // Validate request
  const validation = validateRequest(body, {
    refresh_token: { type: 'string', required: true }
  })
  
  if (!validation.valid) {
    return createErrorResponse('VALIDATION_ERROR', validation.errors.join(', '), 400)
  }

  try {
    const { data, error } = await supabaseClient.auth.refreshSession({
      refresh_token: body.refresh_token
    })
    
    if (error || !data.session) {
      return createErrorResponse('AUTHENTICATION_FAILED', 'Invalid refresh token', 401)
    }

    // Get user profile
    const { data: profile } = await supabaseClient
      .from('users')
      .select('*')
      .eq('id', data.user.id)
      .single()

    const response: AuthResponse = {
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_in: data.session.expires_in,
      user: {
        id: data.user.id,
        email: data.user.email || '',
        display_name: profile?.display_name || data.user.email?.split('@')[0] || '',
        auth_provider: profile?.auth_provider || 'email',
        created_at: data.user.created_at
      }
    }

    return createSuccessResponse(response)

  } catch (error) {
    console.error('Refresh token error:', error)
    return createErrorResponse('INTERNAL_SERVER_ERROR', 'Failed to refresh token', 500)
  }
}