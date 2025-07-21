import { createClient } from '@supabase/supabase-js'
import { createSuccessResponse, createErrorResponse, ErrorCodes } from '../../../_shared/response.ts'
import { AuthenticatedUser } from '../../../_shared/auth-middleware.ts'

interface QuizResult {
  id: string
  user_id: string
  question_id: string
  session_id: string
  user_answer: string
  is_correct: boolean
  time_spent: number
  completed_at: string
}

interface QuizSession {
  id: string
  user_id: string
  category: string
  mode: string
  total_questions: number
  correct_answers: number
  total_time: number
  started_at: string
  completed_at?: string
  results?: QuizResult[]
}

interface SyncRequest {
  sessions: QuizSession[]
  results: QuizResult[]
  last_sync_at?: string
}

interface SyncResponse {
  synced_sessions: number
  synced_results: number
  conflicts: any[]
  last_sync_at: string
}

export async function handleSyncRoutes(req: Request, path: string, user?: AuthenticatedUser): Promise<Response> {
  if (!user) {
    return createErrorResponse(
      ErrorCodes.AUTHENTICATION_FAILED,
      'Authentication required',
      401
    )
  }

  const url = new URL(req.url)
  const method = req.method

  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  try {
    switch (method) {
      case 'GET':
        return await handleGetSync(supabaseClient, user, url)
      
      case 'POST':
        return await handlePostSync(supabaseClient, user, req)
      
      default:
        return createErrorResponse(
          ErrorCodes.VALIDATION_ERROR,
          `Method ${method} not allowed`,
          405
        )
    }
  } catch (error) {
    console.error('Sync API error:', error)
    return createErrorResponse(
      ErrorCodes.INTERNAL_SERVER_ERROR,
      'Internal server error',
      500
    )
  }
}

async function handleGetSync(
  supabaseClient: any,
  user: AuthenticatedUser,
  url: URL
): Promise<Response> {
  try {
    const lastSyncAt = url.searchParams.get('last_sync_at')
    const limit = parseInt(url.searchParams.get('limit') || '100')

    // Get user's quiz sessions
    let sessionsQuery = supabaseClient
      .from('quiz_sessions')
      .select(`
        *,
        quiz_results (*)
      `)
      .eq('user_id', user.id)
      .order('started_at', { ascending: false })
      .limit(limit)

    if (lastSyncAt) {
      sessionsQuery = sessionsQuery.gt('updated_at', lastSyncAt)
    }

    const { data: sessions, error: sessionsError } = await sessionsQuery

    if (sessionsError) {
      console.error('Sessions query error:', sessionsError)
      return createErrorResponse(
        ErrorCodes.INTERNAL_SERVER_ERROR,
        'Failed to fetch user sessions',
        500
      )
    }

    // Get user's quiz results
    let resultsQuery = supabaseClient
      .from('quiz_results')
      .select('*')
      .eq('user_id', user.id)
      .order('completed_at', { ascending: false })
      .limit(limit * 10) // More results than sessions

    if (lastSyncAt) {
      resultsQuery = resultsQuery.gt('completed_at', lastSyncAt)
    }

    const { data: results, error: resultsError } = await resultsQuery

    if (resultsError) {
      console.error('Results query error:', resultsError)
      return createErrorResponse(
        ErrorCodes.INTERNAL_SERVER_ERROR,
        'Failed to fetch user results',
        500
      )
    }

    const syncData = {
      sessions: sessions || [],
      results: results || [],
      last_sync_at: new Date().toISOString(),
      total_sessions: sessions?.length || 0,
      total_results: results?.length || 0
    }

    return createSuccessResponse(syncData)

  } catch (error) {
    console.error('Get sync error:', error)
    return createErrorResponse(
      ErrorCodes.INTERNAL_SERVER_ERROR,
      'Failed to get sync data',
      500
    )
  }
}

async function handlePostSync(
  supabaseClient: any,
  user: AuthenticatedUser,
  req: Request
): Promise<Response> {
  try {
    const syncData = await req.json() as SyncRequest
    const conflicts: any[] = []
    let syncedSessions = 0
    let syncedResults = 0

    // Sync sessions
    if (syncData.sessions && syncData.sessions.length > 0) {
      for (const session of syncData.sessions) {
        try {
          // Ensure user_id matches authenticated user
          session.user_id = user.id

          // Check if session already exists
          const { data: existingSession } = await supabaseClient
            .from('quiz_sessions')
            .select('*')
            .eq('id', session.id)
            .single()

          if (existingSession) {
            // Handle conflict - use latest timestamp
            const existingTime = new Date(existingSession.completed_at || existingSession.started_at)
            const newTime = new Date(session.completed_at || session.started_at)

            if (newTime > existingTime) {
              const { error } = await supabaseClient
                .from('quiz_sessions')
                .update(session)
                .eq('id', session.id)

              if (!error) {
                syncedSessions++
              }
            } else {
              conflicts.push({
                type: 'session',
                id: session.id,
                reason: 'older_timestamp'
              })
            }
          } else {
            // Insert new session
            const { error } = await supabaseClient
              .from('quiz_sessions')
              .insert(session)

            if (!error) {
              syncedSessions++
            }
          }
        } catch (error) {
          console.error('Session sync error:', error)
          conflicts.push({
            type: 'session',
            id: session.id,
            reason: 'sync_error',
            error: String(error)
          })
        }
      }
    }

    // Sync results
    if (syncData.results && syncData.results.length > 0) {
      for (const result of syncData.results) {
        try {
          // Ensure user_id matches authenticated user
          result.user_id = user.id

          // Check if result already exists
          const { data: existingResult } = await supabaseClient
            .from('quiz_results')
            .select('*')
            .eq('id', result.id)
            .single()

          if (existingResult) {
            // Handle conflict - use latest timestamp
            const existingTime = new Date(existingResult.completed_at)
            const newTime = new Date(result.completed_at)

            if (newTime > existingTime) {
              const { error } = await supabaseClient
                .from('quiz_results')
                .update(result)
                .eq('id', result.id)

              if (!error) {
                syncedResults++
              }
            } else {
              conflicts.push({
                type: 'result',
                id: result.id,
                reason: 'older_timestamp'
              })
            }
          } else {
            // Insert new result
            const { error } = await supabaseClient
              .from('quiz_results')
              .insert(result)

            if (!error) {
              syncedResults++
            }
          }
        } catch (error) {
          console.error('Result sync error:', error)
          conflicts.push({
            type: 'result',
            id: result.id,
            reason: 'sync_error',
            error: String(error)
          })
        }
      }
    }

    // Update user's last sync timestamp
    await supabaseClient
      .from('users')
      .update({ last_sync_at: new Date().toISOString() })
      .eq('id', user.id)

    const response: SyncResponse = {
      synced_sessions: syncedSessions,
      synced_results: syncedResults,
      conflicts,
      last_sync_at: new Date().toISOString()
    }

    return createSuccessResponse(response)

  } catch (error) {
    console.error('Post sync error:', error)
    return createErrorResponse(
      ErrorCodes.INTERNAL_SERVER_ERROR,
      'Failed to sync data',
      500
    )
  }
}