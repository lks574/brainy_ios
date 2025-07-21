import { createClient } from '@supabase/supabase-js'
import { createSuccessResponse, createErrorResponse, ErrorCodes } from '../../../_shared/response.ts'
import { AuthenticatedUser } from '../../../_shared/auth-middleware.ts'

// 히스토리 목록 조회
export async function handleHistoryList(req: Request, user: AuthenticatedUser): Promise<Response> {
    try {
        const url = new URL(req.url)
        const category = url.searchParams.get('category')
        const from = url.searchParams.get('from')
        const to = url.searchParams.get('to')
        const limit = parseInt(url.searchParams.get('limit') || '50')
        const offset = parseInt(url.searchParams.get('offset') || '0')

        const supabase = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '')
        let query = supabase
            .from('quiz_sessions')
            .select('*')
            .eq('user_id', user.id)
            .order('started_at', { ascending: false })
            .range(offset, offset + limit - 1)

        if (category) query = query.eq('category', category)
        if (from) query = query.gte('started_at', from)
        if (to) query = query.lte('started_at', to)

        const { data, error } = await query
        if (error) return createErrorResponse(ErrorCodes.INTERNAL_SERVER_ERROR, 'Failed to fetch history', 500)
        return createSuccessResponse({ sessions: data || [] }, { total_count: data?.length || 0 })
    } catch (e) {
        return createErrorResponse(ErrorCodes.INTERNAL_SERVER_ERROR, 'Failed to fetch history', 500)
    }
}

// 히스토리 상세 조회
export async function handleHistoryDetail(req: Request, user: AuthenticatedUser, sessionId: string): Promise<Response> {
    try {
        const supabase = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '')
        const { data, error } = await supabase
            .from('quiz_sessions')
            .select('*, quiz_results(*)')
            .eq('user_id', user.id)
            .eq('id', sessionId)
            .single()
        if (error || !data) return createErrorResponse(ErrorCodes.RESOURCE_NOT_FOUND, 'Session not found', 404)
        return createSuccessResponse(data)
    } catch (e) {
        return createErrorResponse(ErrorCodes.INTERNAL_SERVER_ERROR, 'Failed to fetch session detail', 500)
    }
}

// 통계 데이터 조회
export async function handleHistoryStats(req: Request, user: AuthenticatedUser): Promise<Response> {
    try {
        const url = new URL(req.url)
        const category = url.searchParams.get('category')
        const from = url.searchParams.get('from')
        const to = url.searchParams.get('to')
        const supabase = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '')
        let query = supabase
            .from('quiz_sessions')
            .select('category, correct_answers, total_questions, total_time, started_at, completed_at')
            .eq('user_id', user.id)
        if (category) query = query.eq('category', category)
        if (from) query = query.gte('started_at', from)
        if (to) query = query.lte('started_at', to)
        const { data, error } = await query
        if (error) return createErrorResponse(ErrorCodes.INTERNAL_SERVER_ERROR, 'Failed to fetch stats', 500)
        // 간단 통계 집계
        const total = data?.length || 0
        const totalCorrect = data?.reduce((sum, s) => sum + (s.correct_answers || 0), 0) || 0
        const totalQuestions = data?.reduce((sum, s) => sum + (s.total_questions || 0), 0) || 0
        const totalTime = data?.reduce((sum, s) => sum + (s.total_time || 0), 0) || 0
        return createSuccessResponse({ total, totalCorrect, totalQuestions, totalTime })
    } catch (e) {
        return createErrorResponse(ErrorCodes.INTERNAL_SERVER_ERROR, 'Failed to fetch stats', 500)
    }
}

// 라우터
export async function handleHistoryRoutes(req: Request, path: string, user: AuthenticatedUser): Promise<Response> {
    const url = new URL(req.url)
    if (url.pathname.endsWith('/list')) {
        return handleHistoryList(req, user)
    } else if (url.pathname.includes('/detail/')) {
        const sessionId = url.pathname.split('/detail/')[1]
        return handleHistoryDetail(req, user, sessionId)
    } else if (url.pathname.endsWith('/stats')) {
        return handleHistoryStats(req, user)
    } else {
        return createErrorResponse(ErrorCodes.RESOURCE_NOT_FOUND, 'Not found', 404)
    }
} 