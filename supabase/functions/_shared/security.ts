import { corsHeaders } from './cors.ts'

export interface SecurityHeaders {
  [key: string]: string
}

export const securityHeaders: SecurityHeaders = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https:; font-src 'self' data:;",
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=(), usb=()',
  'X-Robots-Tag': 'noindex, nofollow',
  'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
  'Pragma': 'no-cache',
  'Expires': '0'
}

export function addSecurityHeaders(headers: Record<string, string> = {}): Record<string, string> {
  return {
    ...corsHeaders,
    ...securityHeaders,
    ...headers
  }
}

export function sanitizeInput(input: string): string {
  if (typeof input !== 'string') return ''
  
  return input
    .replace(/[<>]/g, '') // Remove potential HTML tags
    .replace(/javascript:/gi, '') // Remove javascript: protocol
    .replace(/on\w+=/gi, '') // Remove event handlers
    .trim()
}

export function validateContentType(req: Request, expectedTypes: string[] = ['application/json']): boolean {
  const contentType = req.headers.get('content-type')
  if (!contentType) return false
  
  return expectedTypes.some(type => contentType.includes(type))
}

export function isValidOrigin(req: Request, allowedOrigins: string[] = ['*']): boolean {
  if (allowedOrigins.includes('*')) return true
  
  const origin = req.headers.get('origin')
  if (!origin) return false
  
  return allowedOrigins.includes(origin)
}

export function generateRequestId(): string {
  return `req_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`
}

export function logRequest(req: Request, requestId: string, startTime: number) {
  const duration = Date.now() - startTime
  const method = req.method
  const url = new URL(req.url)
  const userAgent = req.headers.get('user-agent') || 'unknown'
  const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
  
  console.log(JSON.stringify({
    requestId,
    method,
    path: url.pathname,
    query: url.search,
    userAgent,
    ip,
    duration,
    timestamp: new Date().toISOString()
  }))
}