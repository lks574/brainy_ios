import { createClient } from '@supabase/supabase-js'
import { createSuccessResponse, createErrorResponse, ErrorCodes } from '../../../_shared/response.ts'
import { AuthenticatedUser } from '../../../_shared/auth-middleware.ts'

interface QuizVersion {
  version: string
  last_updated: string
  categories: string[]
}

interface QuizQuestion {
  id: string
  question: string
  correct_answer: string
  options?: string[]
  category: string
  difficulty: string
  type: string
  audio_url?: string
  version: string
  created_at: string
}

interface QuizDataResponse {
  version: string
  questions: QuizQuestion[]
  total_count: number
}

export async function handleQuizRoutes(req: Request, path: string, user?: AuthenticatedUser): Promise<Response> {
  const url = new URL(req.url)
  const method = req.method
  const pathSegments = url.pathname.split('/').filter(Boolean)
  
  // Extract the action from the path
  const action = pathSegments[pathSegments.length - 1] || 'version'

  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  try {
    switch (method) {
      case 'GET':
        return await handleGetRequest(supabaseClient, action, url)
      
      default:
        return createErrorResponse(
          ErrorCodes.VALIDATION_ERROR,
          `Method ${method} not allowed`,
          405
        )
    }
  } catch (error) {
    console.error('Quiz API error:', error)
    return createErrorResponse(
      ErrorCodes.INTERNAL_SERVER_ERROR,
      'Internal server error',
      500
    )
  }
}

async function handleGetRequest(
  supabaseClient: any,
  action: string,
  url: URL
): Promise<Response> {
  switch (action) {
    case 'version':
      return await getQuizVersion(supabaseClient)
    
    case 'data':
      return await getQuizData(supabaseClient, url)
    
    case 'categories':
      return await getQuizCategories(supabaseClient)
    
    default:
      // Check if it's a category-specific request
      const category = action
      return await getQuizByCategory(supabaseClient, category, url)
  }
}

async function getQuizVersion(supabaseClient: any): Promise<Response> {
  try {
    const { data: versionData, error: versionError } = await supabaseClient
      .from('quiz_versions')
      .select('*')
      .eq('is_current', true)
      .single()

    if (versionError) {
      console.error('Version query error:', versionError)
      return createErrorResponse(
        ErrorCodes.RESOURCE_NOT_FOUND,
        'Quiz version not found',
        404
      )
    }

    const { data: categories, error: categoriesError } = await supabaseClient
      .from('quiz_questions')
      .select('category')
      .eq('is_active', true)
      .eq('version', versionData.version)

    if (categoriesError) {
      console.error('Categories query error:', categoriesError)
    }

    const uniqueCategories = [...new Set((categories || []).map((c: any) => c.category as string))]

    const versionResponse: QuizVersion = {
      version: versionData.version,
      last_updated: versionData.created_at,
      categories: uniqueCategories
    }

    return createSuccessResponse(versionResponse)

  } catch (error) {
    console.error('Get quiz version error:', error)
    return createErrorResponse(
      ErrorCodes.INTERNAL_SERVER_ERROR,
      'Failed to get quiz version',
      500
    )
  }
}

async function getQuizData(supabaseClient: any, url: URL): Promise<Response> {
  try {
    const category = url.searchParams.get('category')
    const limit = parseInt(url.searchParams.get('limit') || '50')
    const offset = parseInt(url.searchParams.get('offset') || '0')

    let query = supabaseClient
      .from('quiz_questions')
      .select('*')
      .eq('is_active', true)
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false })

    if (category) {
      query = query.eq('category', category)
    }

    const { data: questions, error } = await query

    if (error) {
      console.error('Quiz data query error:', error)
      return createErrorResponse(
        ErrorCodes.INTERNAL_SERVER_ERROR,
        'Failed to fetch quiz data',
        500
      )
    }

    // Get current version
    const { data: versionData } = await supabaseClient
      .from('quiz_versions')
      .select('version')
      .eq('is_current', true)
      .single()

    const response: QuizDataResponse = {
      version: versionData?.version || '1.0.0',
      questions: questions || [],
      total_count: questions?.length || 0
    }

    return createSuccessResponse(response, {
      total_count: questions?.length || 0,
      page: Math.floor(offset / limit) + 1,
      per_page: limit
    })

  } catch (error) {
    console.error('Get quiz data error:', error)
    return createErrorResponse(
      ErrorCodes.INTERNAL_SERVER_ERROR,
      'Failed to get quiz data',
      500
    )
  }
}

async function getQuizCategories(supabaseClient: any): Promise<Response> {
  try {
    const { data: categories, error } = await supabaseClient
      .from('quiz_questions')
      .select('category')
      .eq('is_active', true)

    if (error) {
      console.error('Categories query error:', error)
      return createErrorResponse(
        ErrorCodes.INTERNAL_SERVER_ERROR,
        'Failed to fetch categories',
        500
      )
    }

    const uniqueCategories = [...new Set((categories || []).map((c: any) => c.category as string))]

    return createSuccessResponse({ categories: uniqueCategories })

  } catch (error) {
    console.error('Get quiz categories error:', error)
    return createErrorResponse(
      ErrorCodes.INTERNAL_SERVER_ERROR,
      'Failed to get quiz categories',
      500
    )
  }
}

async function getQuizByCategory(
  supabaseClient: any,
  category: string,
  url: URL
): Promise<Response> {
  try {
    const limit = parseInt(url.searchParams.get('limit') || '20')
    const offset = parseInt(url.searchParams.get('offset') || '0')
    const difficulty = url.searchParams.get('difficulty')

    let query = supabaseClient
      .from('quiz_questions')
      .select('*')
      .eq('is_active', true)
      .eq('category', category)
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false })

    if (difficulty) {
      query = query.eq('difficulty', difficulty)
    }

    const { data: questions, error } = await query

    if (error) {
      console.error('Category quiz query error:', error)
      return createErrorResponse(
        ErrorCodes.INTERNAL_SERVER_ERROR,
        'Failed to fetch quiz by category',
        500
      )
    }

    return createSuccessResponse(questions || [], {
      category,
      total_count: questions?.length || 0,
      page: Math.floor(offset / limit) + 1,
      per_page: limit
    })

  } catch (error) {
    console.error('Get quiz by category error:', error)
    return createErrorResponse(
      ErrorCodes.INTERNAL_SERVER_ERROR,
      'Failed to get quiz by category',
      500
    )
  }
}