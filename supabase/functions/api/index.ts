import { withMiddleware, middlewareConfigs } from '../_shared/middleware.ts'
import { createSuccessResponse } from '../_shared/response.ts'
import { APIRouter } from '../_shared/router.ts'

// Import route handlers
import { handleQuizRoutes } from './v1/quiz/index.ts'
import { handleSyncRoutes } from './v1/sync/index.ts'

// Create main API router
const apiRouter = new APIRouter()

// Health check endpoint
apiRouter.get('/api/health', async () => {
  const healthData = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    services: {
      database: { status: 'healthy', response_time: 0 },
      auth: { status: 'healthy', response_time: 0 },
      storage: { status: 'healthy', response_time: 0 }
    }
  }
  
  return createSuccessResponse(healthData)
})

// API version info
apiRouter.get('/api/version', async () => {
  return createSuccessResponse({
    version: '1.0.0',
    api_version: 'v1',
    build_time: new Date().toISOString(),
    endpoints: [
      '/api/health',
      '/api/version',
      '/api/v1/quiz/*',
      '/api/v1/sync/*'
    ]
  })
})

// Quiz routes - delegate to quiz handler
apiRouter.all('/api/v1/quiz/*', async (req, params) => {
  const path = new URL(req.url).pathname.replace('/api/v1/quiz/', '')
  return handleQuizRoutes(req, path)
})

// Sync routes - delegate to sync handler
apiRouter.all('/api/v1/sync/*', async (req, params) => {
  const path = new URL(req.url).pathname.replace('/api/v1/sync/', '')
  return handleSyncRoutes(req, path)
})

// Main API handler
async function apiHandler(req: Request): Promise<Response> {
  return await apiRouter.handle(req)
}

// Export the main handler with middleware
export default withMiddleware(apiHandler, middlewareConfigs.api)