import { createClient } from 'jsr:@supabase/supabase-js@2'
import { withMiddleware, middlewareConfigs } from '../_shared/middleware.ts'
import { createSuccessResponse } from '../_shared/response.ts'

interface HealthCheckResponse {
  status: 'healthy' | 'degraded' | 'unhealthy'
  timestamp: string
  services: {
    database: { status: string; response_time: number }
    auth: { status: string; response_time: number }
    storage: { status: string; response_time: number }
  }
  version: string
}

async function healthHandler(_req: Request): Promise<Response> {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Test database connection
    const dbStart = Date.now()
    let dbStatus = 'healthy'
    let dbResponseTime = 0
    
    try {
      const { error } = await supabaseClient
        .from('users')
        .select('count')
        .limit(1)
      
      dbResponseTime = Date.now() - dbStart
      if (error) {
        dbStatus = 'degraded'
        console.warn('Database health check warning:', error.message)
      }
    } catch (error) {
      dbStatus = 'unhealthy'
      dbResponseTime = Date.now() - dbStart
      console.error('Database health check failed:', error)
    }

    // Test auth service
    const authStart = Date.now()
    let authStatus = 'healthy'
    let authResponseTime = 0
    
    try {
      // Try to get current user (will fail but service should respond)
      await supabaseClient.auth.getUser()
      authResponseTime = Date.now() - authStart
    } catch (error) {
      authStatus = 'degraded'
      authResponseTime = Date.now() - authStart
      console.warn('Auth service health check warning:', error)
    }

    // Test storage service
    const storageStart = Date.now()
    let storageStatus = 'healthy'
    let storageResponseTime = 0
    
    try {
      const { error } = await supabaseClient.storage.listBuckets()
      storageResponseTime = Date.now() - storageStart
      if (error) {
        storageStatus = 'degraded'
        console.warn('Storage health check warning:', error.message)
      }
    } catch (error) {
      storageStatus = 'unhealthy'
      storageResponseTime = Date.now() - storageStart
      console.error('Storage health check failed:', error)
    }

    // Determine overall status
    let overallStatus: 'healthy' | 'degraded' | 'unhealthy' = 'healthy'
    
    if (dbStatus === 'unhealthy' || authStatus === 'unhealthy' || storageStatus === 'unhealthy') {
      overallStatus = 'unhealthy'
    } else if (dbStatus === 'degraded' || authStatus === 'degraded' || storageStatus === 'degraded') {
      overallStatus = 'degraded'
    }

    const healthData: HealthCheckResponse = {
      status: overallStatus,
      timestamp: new Date().toISOString(),
      services: {
        database: { status: dbStatus, response_time: dbResponseTime },
        auth: { status: authStatus, response_time: authResponseTime },
        storage: { status: storageStatus, response_time: storageResponseTime }
      },
      version: '1.0.0'
    }

    return createSuccessResponse(healthData)

  } catch (error) {
    console.error('Health check error:', error)
    
    const healthData: HealthCheckResponse = {
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      services: {
        database: { status: 'unknown', response_time: 0 },
        auth: { status: 'unknown', response_time: 0 },
        storage: { status: 'unknown', response_time: 0 }
      },
      version: '1.0.0'
    }

    return createSuccessResponse(healthData)
  }
}

// Export the handler with public middleware (no auth required)
Deno.serve(withMiddleware(healthHandler, middlewareConfigs.public))