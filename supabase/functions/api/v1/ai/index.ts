import { createSuccessResponse, createErrorResponse, ErrorCodes } from '../../../_shared/response.ts'
import { AuthenticatedUser } from '../../../_shared/auth-middleware.ts'

// OpenAI API 호출 함수 (예시)
async function callOpenAI(prompt: string): Promise<any> {
    const apiKey = Deno.env.get('OPENAI_API_KEY')
    const url = 'https://api.openai.com/v1/chat/completions'
    const body = {
        model: 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 256
    }
    const res = await fetch(url, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(body)
    })
    if (!res.ok) throw new Error('OpenAI API error')
    return await res.json()
}

// 퀴즈 생성 요청 핸들러
export async function handleAIQuiz(req: Request, user: AuthenticatedUser): Promise<Response> {
    try {
        const { prompt } = await req.json()
        // 사용량 제한(예시: 1분 1회)
        // 실제 구현 시 DB/Redis 등으로 추적 필요
        // ...
        // OpenAI 호출
        let aiResult
        try {
            aiResult = await callOpenAI(prompt)
        } catch (e) {
            // 폴백: 기본 퀴즈 반환
            return createSuccessResponse({
                fallback: true,
                question: '기본 퀴즈 문제입니다.',
                options: ['A', 'B', 'C', 'D'],
                answer: 'A'
            })
        }
        // 검증(예시: 필수 필드 체크)
        // 실제로는 더 엄격한 검증 필요
        if (!aiResult.choices || !aiResult.choices[0]?.message?.content) {
            return createErrorResponse(ErrorCodes.VALIDATION_ERROR, 'Invalid AI response', 400)
        }
        // 결과 반환
        return createSuccessResponse({
            question: aiResult.choices[0].message.content
        })
    } catch (e) {
        return createErrorResponse(ErrorCodes.INTERNAL_SERVER_ERROR, 'Failed to generate AI quiz', 500)
    }
}

// 라우터
export async function handleAIRoutes(req: Request, path: string, user: AuthenticatedUser): Promise<Response> {
    if (req.method === 'POST' && path.endsWith('/quiz')) {
        return handleAIQuiz(req, user)
    } else {
        return createErrorResponse(ErrorCodes.RESOURCE_NOT_FOUND, 'Not found', 404)
    }
} 