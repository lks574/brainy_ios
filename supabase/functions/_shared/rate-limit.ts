import { createErrorResponse } from './response.ts'

interface RateLimitConfig {
  requests: number
  window: number // in seconds
  identifier?: (req: Request) => string
}

interface RateLimitEntry {
  count: number
  resetTime: number
}

// In-memory store for rate limiting (in production, use Redis)
const rateLimitStore = new Map<string, RateLimitEntry>()

export function withRateLimit(
  config: RateLimitConfig,
  handler: (req: Request) => Promise<Response>
) {
  return async (req: Request): Promise<Response> => {
    const identifier = config.identifier ? config.identifier(req) : getClientIdentifier(req)
    const now = Date.now()
    const windowStart = now - (config.window * 1000)

    // Clean up expired entries
    cleanupExpiredEntries(windowStart)

    const entry = rateLimitStore.get(identifier)
    
    if (!entry) {
      // First request from this identifier
      rateLimitStore.set(identifier, {
        count: 1,
        resetTime: now + (config.window * 1000)
      })
      return handler(req)
    }

    if (now > entry.resetTime) {
      // Window has expired, reset counter
      rateLimitStore.set(identifier, {
        count: 1,
        resetTime: now + (config.window * 1000)
      })
      return handler(req)
    }

    if (entry.count >= config.requests) {
      // Rate limit exceeded
      const resetIn = Math.ceil((entry.resetTime - now) / 1000)
      return createErrorResponse(
        'RATE_LIMIT_EXCEEDED',
        `Rate limit exceeded. Try again in ${resetIn} seconds.`,
        429,
        {
          limit: config.requests,
          window: config.window,
          resetIn
        }
      )
    }

    // Increment counter
    entry.count++
    rateLimitStore.set(identifier, entry)

    return handler(req)
  }
}

function getClientIdentifier(req: Request): string {
  // Try to get IP from various headers
  const forwarded = req.headers.get('x-forwarded-for')
  const realIp = req.headers.get('x-real-ip')
  const cfConnectingIp = req.headers.get('cf-connecting-ip')
  
  if (forwarded) {
    return forwarded.split(',')[0].trim()
  }
  
  if (realIp) {
    return realIp
  }
  
  if (cfConnectingIp) {
    return cfConnectingIp
  }
  
  // Fallback to user agent + some randomness
  const userAgent = req.headers.get('user-agent') || 'unknown'
  return `fallback-${userAgent.slice(0, 50)}`
}

function cleanupExpiredEntries(windowStart: number) {
  for (const [key, entry] of rateLimitStore.entries()) {
    if (entry.resetTime < windowStart) {
      rateLimitStore.delete(key)
    }
  }
}

// Predefined rate limit configurations
export const rateLimitConfigs = {
  auth: {
    requests: 5,
    window: 900 // 15 minutes
  },
  api: {
    requests: 100,
    window: 3600 // 1 hour
  },
  sync: {
    requests: 50,
    window: 3600 // 1 hour
  },
  ai: {
    requests: 10,
    window: 3600 // 1 hour
  }
}