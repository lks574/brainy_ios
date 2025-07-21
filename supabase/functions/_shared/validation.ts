export interface ValidationRule {
  type: 'string' | 'number' | 'boolean' | 'array' | 'object'
  required?: boolean
  minLength?: number
  maxLength?: number
  min?: number
  max?: number
  format?: 'email' | 'url' | 'uuid'
  enum?: string[]
}

export interface ValidationSchema {
  [key: string]: ValidationRule
}

interface ValidationResult {
  valid: boolean
  errors: string[]
}

export function validateRequest(data: any, schema: ValidationSchema): ValidationResult {
  const errors: string[] = []

  for (const [field, rule] of Object.entries(schema)) {
    const value = data[field]

    // Check required fields
    if (rule.required && (value === undefined || value === null || value === '')) {
      errors.push(`${field} is required`)
      continue
    }

    // Skip validation if field is not required and not provided
    if (!rule.required && (value === undefined || value === null)) {
      continue
    }

    // Type validation
    if (rule.type === 'string' && typeof value !== 'string') {
      errors.push(`${field} must be a string`)
      continue
    }

    if (rule.type === 'number' && typeof value !== 'number') {
      errors.push(`${field} must be a number`)
      continue
    }

    if (rule.type === 'boolean' && typeof value !== 'boolean') {
      errors.push(`${field} must be a boolean`)
      continue
    }

    if (rule.type === 'array' && !Array.isArray(value)) {
      errors.push(`${field} must be an array`)
      continue
    }

    if (rule.type === 'object' && (typeof value !== 'object' || Array.isArray(value))) {
      errors.push(`${field} must be an object`)
      continue
    }

    // String validations
    if (rule.type === 'string' && typeof value === 'string') {
      if (rule.minLength && value.length < rule.minLength) {
        errors.push(`${field} must be at least ${rule.minLength} characters long`)
      }

      if (rule.maxLength && value.length > rule.maxLength) {
        errors.push(`${field} must be no more than ${rule.maxLength} characters long`)
      }

      if (rule.format === 'email' && !isValidEmail(value)) {
        errors.push(`${field} must be a valid email address`)
      }

      if (rule.format === 'url' && !isValidUrl(value)) {
        errors.push(`${field} must be a valid URL`)
      }

      if (rule.format === 'uuid' && !isValidUuid(value)) {
        errors.push(`${field} must be a valid UUID`)
      }

      if (rule.enum && !rule.enum.includes(value)) {
        errors.push(`${field} must be one of: ${rule.enum.join(', ')}`)
      }
    }

    // Number validations
    if (rule.type === 'number' && typeof value === 'number') {
      if (rule.min !== undefined && value < rule.min) {
        errors.push(`${field} must be at least ${rule.min}`)
      }

      if (rule.max !== undefined && value > rule.max) {
        errors.push(`${field} must be no more than ${rule.max}`)
      }
    }
  }

  return {
    valid: errors.length === 0,
    errors
  }
}

function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

function isValidUrl(url: string): boolean {
  try {
    new URL(url)
    return true
  } catch {
    return false
  }
}

function isValidUuid(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}