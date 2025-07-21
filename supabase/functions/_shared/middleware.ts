import { withAuth, AuthMiddlewareOptions, AuthenticatedUser } from './auth-middleware.ts'
import { withRateLimit, rateLimitConfigs } from './rate-limit.ts'
import { validateRequest, ValidationSchema } from './validation.ts'
import { createErrorResponse, ErrorCodes } from './response.ts'
import { addSecurityHeaders, generateRequestId, logRequest, validateContentType, isValidOrigin } from './security.ts'

export interface MiddlewareOptions {
  auth?: AuthMiddlewareOptions
  rateLimit?: {
    requests: number
    window: number
    identifier?: (req: Request) => string
  }
  validation?: {
    body?: ValidationSchema
    query?: ValidationSchema
  }
  security?: {
    allowedOrigins?: string[]
    requireContentType?: string[]
  }
  logging?: boolean
}

export type HandlerFunction = (req: Request, user?: AuthenticatedUser) => Promise<Response>

export function withMiddleware(
  handler: HandlerFunction,
  options: MiddlewareOptions = {}
) {
  return async (req: Request): Promise<Response> => {
    const requestId = generateRequestId()
    const startTime = Date.now()

    try {
      // Handle preflight requests
      if (req.method === 'OPTIONS') {
        return new Response(null, {
          status: 200,
          headers: addSecurityHeaders({
            'X-Request-ID': requestId
          })
        })
      }

      // Security checks
      if (options.security?.allowedOrigins && !isValidOrigin(req, options.security.allowedOrigins)) {
        return createErrorResponse(ErrorCodes.AUTHORIZATION_FAILED, 'Origin not allowed', 403)
      }

      if (options.security?.requireContentType && req.method !== 'GET' && req.method !== 'DELETE') {
        if (!validateContentType(req, options.security.requireContentType)) {
          return createErrorResponse(ErrorCodes.VALIDATION_ERROR, 'Invalid content type', 400)
        }
      }

      // Request validation
      if (options.validation) {
        const validationResult = await validateRequestData(req, options.validation)
        if (!validationResult.valid) {
          return createErrorResponse(
            ErrorCodes.VALIDATION_ERROR,
            'Validation failed',
            400,
            { errors: validationResult.errors }
          )
        }
      }

      // Create the final handler with auth middleware
      let finalHandler = handler

      if (options.auth) {
        finalHandler = (req: Request) => withAuth(req, handler, options.auth)
      }

      // Apply rate limiting if configured
      if (options.rateLimit) {
        finalHandler = withRateLimit(options.rateLimit, finalHandler)
      }

      // Execute the handler
      const response = await finalHandler(req)

      // Add security headers and request ID to response
      const responseHeaders = new Headers(response.headers)
      const securityHeaders = addSecurityHeaders({
        'X-Request-ID': requestId
      })
      
      for (const [key, value] of Object.entries(securityHeaders)) {
        if (!responseHeaders.has(key)) {
          responseHeaders.set(key, String(value))
        }
      }

      // Log request if enabled
      if (options.logging !== false) {
        logRequest(req, requestId, startTime)
      }

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: responseHeaders
      })

    } catch (error) {
      console.error('Middleware error:', error)
      
      if (options.logging !== false) {
        console.error(JSON.stringify({
          requestId,
          error: error.message,
          stack: error.stack,
          timestamp: new Date().toISOString()
        }))
      }

      const errorHeaders = addSecurityHeaders({
        'X-Request-ID': requestId
      })

      return new Response(JSON.stringify({
        success: false,
        error: {
          code: ErrorCodes.INTERNAL_SERVER_ERROR,
          message: 'Internal server error',
          requestId
        }
      }), {
        status: 500,
        headers: {
          ...errorHeaders,
          'Content-Type': 'application/json'
        }
      })
    }
  }
}

async function validateRequestData(
  req: Request,
  validation: { body?: ValidationSchema; query?: ValidationSchema }
): Promise<{ valid: boolean; errors: string[] }> {
  const errors: string[] = []

  // Validate query parameters
  if (validation.query) {
    const url = new URL(req.url)
    const queryParams: Record<string, string> = {}
    
    for (const [key, value] of url.searchParams.entries()) {
      queryParams[key] = value
    }

    const queryValidation = validateRequest(queryParams, validation.query)
    if (!queryValidation.valid) {
      errors.push(...queryValidation.errors.map(err => `Query: ${err}`))
    }
  }

  // Validate request body
  if (validation.body && req.method !== 'GET' && req.method !== 'DELETE') {
    try {
      const contentType = req.headers.get('content-type')
      
      if (contentType?.includes('application/json')) {
        const body = await req.json()
        const bodyValidation = validateRequest(body, validation.body)
        if (!bodyValidation.valid) {
          errors.push(...bodyValidation.errors.map(err => `Body: ${err}`))
        }
      } else if (contentType?.includes('application/x-www-form-urlencoded')) {
        const formData = await req.formData()
        const body: Record<string, string> = {}
        
        for (const [key, value] of formData.entries()) {
          body[key] = value.toString()
        }
        
        const bodyValidation = validateRequest(body, validation.body)
        if (!bodyValidation.valid) {
          errors.push(...bodyValidation.errors.map(err => `Body: ${err}`))
        }
      }
    } catch (error) {
      if (error instanceof SyntaxError) {
        errors.push('Body: Invalid JSON format')
      } else {
        errors.push('Body: Failed to parse request body')
      }
    }
  }

  return {
    valid: errors.length === 0,
    errors
  }
}

// Predefined middleware configurations for different API types
export const middlewareConfigs = {
  auth: {
    rateLimit: rateLimitConfigs.auth,
    security: {
      requireContentType: ['application/json']
    },
    logging: true
  },
  
  api: {
    auth: { requireAuth: true },
    rateLimit: rateLimitConfigs.api,
    security: {
      requireContentType: ['application/json']
    },
    logging: true
  },
  
  sync: {
    auth: { requireAuth: true },
    rateLimit: rateLimitConfigs.sync,
    security: {
      requireContentType: ['application/json']
    },
    logging: true
  },
  
  ai: {
    auth: { requireAuth: true },
    rateLimit: rateLimitConfigs.ai,
    security: {
      requireContentType: ['application/json']
    },
    logging: true
  },
  
  admin: {
    auth: { requireAuth: true, requireAdmin: true },
    rateLimit: rateLimitConfigs.api,
    security: {
      requireContentType: ['application/json']
    },
    logging: true
  },
  
  public: {
    auth: { requireAuth: false },
    rateLimit: rateLimitConfigs.api,
    logging: true
  }
}