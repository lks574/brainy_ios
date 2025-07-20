import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createErrorResponse } from './response.ts'

export interface AuthenticatedUser {
  id: string
  email: string
  display_name: string
  auth_provider: string
  role: 'user' | 'admin'
}

export interface AuthMiddlewareOptions {
  requireAuth?: boolean
  requireAdmin?: boolean
}

export async function withAuth(
  req: Request,
  handler: (req: Request, user?: AuthenticatedUser) => Promise<Response>,
  options: AuthMiddlewareOptions = { requireAuth: true }
): Promise<Response> {
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  // Extract token from Authorization header
  const authHeader = req.headers.get('Authorization')
  
  if (!authHeader && options.requireAuth) {
    return createErrorResponse('AUTHENTICATION_FAILED', 'Missing authorization header', 401)
  }

  if (!authHeader && !options.requireAuth) {
    return handler(req)
  }

  const token = authHeader?.replace('Bearer ', '')
  
  if (!token && options.requireAuth) {
    return createErrorResponse('AUTHENTICATION_FAILED', 'Invalid authorization header format', 401)
  }

  try {
    // Verify JWT token with Supabase
    const { data: { user }, error } = await supabaseClient.auth.getUser(token)
    
    if (error || !user) {
      if (options.requireAuth) {
        return createErrorResponse('AUTHENTICATION_FAILED', 'Invalid or expired token', 401)
      }
      return handler(req)
    }

    // Get user profile from database
    const { data: profile, error: profileError } = await supabaseClient
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single()

    if (profileError && options.requireAuth) {
      return createErrorResponse('AUTHENTICATION_FAILED', 'User profile not found', 401)
    }

    const authenticatedUser: AuthenticatedUser = {
      id: user.id,
      email: user.email || '',
      display_name: profile?.display_name || user.email?.split('@')[0] || '',
      auth_provider: profile?.auth_provider || 'email',
      role: profile?.metadata?.role || 'user'
    }

    // Check admin requirement
    if (options.requireAdmin && authenticatedUser.role !== 'admin') {
      return createErrorResponse('AUTHORIZATION_FAILED', 'Admin access required', 403)
    }

    return handler(req, authenticatedUser)

  } catch (error) {
    console.error('Auth middleware error:', error)
    if (options.requireAuth) {
      return createErrorResponse('INTERNAL_SERVER_ERROR', 'Authentication verification failed', 500)
    }
    return handler(req)
  }
}

export function extractBearerToken(req: Request): string | null {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null
  }
  return authHeader.replace('Bearer ', '')
}

export async function verifyJWTToken(token: string): Promise<{ valid: boolean; user?: any; error?: string }> {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: { user }, error } = await supabaseClient.auth.getUser(token)
    
    if (error || !user) {
      return { valid: false, error: 'Invalid or expired token' }
    }

    return { valid: true, user }

  } catch (error) {
    return { valid: false, error: 'Token verification failed' }
  }
}

export async function refreshAccessToken(refreshToken: string): Promise<{ success: boolean; tokens?: any; error?: string }> {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data, error } = await supabaseClient.auth.refreshSession({
      refresh_token: refreshToken
    })
    
    if (error || !data.session) {
      return { success: false, error: 'Failed to refresh token' }
    }

    return { 
      success: true, 
      tokens: {
        access_token: data.session.access_token,
        refresh_token: data.session.refresh_token,
        expires_in: data.session.expires_in
      }
    }

  } catch (error) {
    return { success: false, error: 'Token refresh failed' }
  }
}