import { corsHeaders } from './cors.ts'

interface APIResponse<T> {
  success: boolean
  data?: T
  error?: {
    code: string
    message: string
    details?: any
  }
  meta?: {
    total_count?: number
    page?: number
    per_page?: number
    version?: string
  }
}

export function createSuccessResponse<T>(data: T, meta?: any): Response {
  const response: APIResponse<T> = {
    success: true,
    data,
    ...(meta && { meta })
  }

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json'
    }
  })
}

export function createErrorResponse(code: string, message: string, status: number = 400, details?: any): Response {
  const response: APIResponse<null> = {
    success: false,
    error: {
      code,
      message,
      ...(details && { details })
    }
  }

  return new Response(JSON.stringify(response), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json'
    }
  })
}

export enum ErrorCodes {
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  AUTHENTICATION_FAILED = 'AUTHENTICATION_FAILED',
  AUTHORIZATION_FAILED = 'AUTHORIZATION_FAILED',
  RESOURCE_NOT_FOUND = 'RESOURCE_NOT_FOUND',
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  INTERNAL_SERVER_ERROR = 'INTERNAL_SERVER_ERROR',
  EXTERNAL_SERVICE_ERROR = 'EXTERNAL_SERVICE_ERROR'
}