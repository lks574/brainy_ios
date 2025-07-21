import { createErrorResponse, ErrorCodes } from './response.ts'

export interface RouteHandler {
  (req: Request, params: Record<string, string>, context?: any): Promise<Response>
}

export interface Route {
  method: string | string[]
  path: string | RegExp
  handler: RouteHandler
  middleware?: any[]
}

export class APIRouter {
  private routes: Route[] = []
  private basePath: string

  constructor(basePath: string = '') {
    this.basePath = basePath
  }

  // HTTP method helpers
  get(path: string | RegExp, handler: RouteHandler, middleware?: any[]) {
    this.addRoute('GET', path, handler, middleware)
  }

  post(path: string | RegExp, handler: RouteHandler, middleware?: any[]) {
    this.addRoute('POST', path, handler, middleware)
  }

  put(path: string | RegExp, handler: RouteHandler, middleware?: any[]) {
    this.addRoute('PUT', path, handler, middleware)
  }

  patch(path: string | RegExp, handler: RouteHandler, middleware?: any[]) {
    this.addRoute('PATCH', path, handler, middleware)
  }

  delete(path: string | RegExp, handler: RouteHandler, middleware?: any[]) {
    this.addRoute('DELETE', path, handler, middleware)
  }

  all(path: string | RegExp, handler: RouteHandler, middleware?: any[]) {
    this.addRoute(['GET', 'POST', 'PUT', 'PATCH', 'DELETE'], path, handler, middleware)
  }

  private addRoute(method: string | string[], path: string | RegExp, handler: RouteHandler, middleware?: any[]) {
    this.routes.push({
      method,
      path: this.normalizePath(path),
      handler,
      middleware
    })
  }

  private normalizePath(path: string | RegExp): string | RegExp {
    if (path instanceof RegExp) {
      return path
    }

    const fullPath = this.basePath + path
    return fullPath.replace(/\/+/g, '/') // Remove duplicate slashes
  }

  // Route matching
  match(method: string, pathname: string): { route: Route; params: Record<string, string> } | null {
    for (const route of this.routes) {
      const methods = Array.isArray(route.method) ? route.method : [route.method]
      
      if (!methods.includes(method)) {
        continue
      }

      const match = this.matchPath(route.path, pathname)
      if (match) {
        return { route, params: match.params }
      }
    }

    return null
  }

  private matchPath(routePath: string | RegExp, pathname: string): { params: Record<string, string> } | null {
    if (routePath instanceof RegExp) {
      const match = pathname.match(routePath)
      if (match) {
        const params: Record<string, string> = {}
        // Extract named groups if available
        if (match.groups) {
          Object.assign(params, match.groups)
        }
        // Extract numbered groups
        for (let i = 1; i < match.length; i++) {
          params[`$${i}`] = match[i]
        }
        return { params }
      }
      return null
    }

    // Convert string path to regex with parameter extraction
    const paramNames: string[] = []
    const regexPath = routePath
      .replace(/:[^/]+/g, (match) => {
        paramNames.push(match.slice(1)) // Remove the ':'
        return '([^/]+)'
      })
      .replace(/\*/g, '(.*)')

    const regex = new RegExp(`^${regexPath}$`)
    const match = pathname.match(regex)

    if (match) {
      const params: Record<string, string> = {}
      for (let i = 0; i < paramNames.length; i++) {
        params[paramNames[i]] = match[i + 1]
      }
      return { params }
    }

    return null
  }

  // Handle request
  async handle(req: Request): Promise<Response> {
    const url = new URL(req.url)
    const method = req.method
    const pathname = url.pathname

    const match = this.match(method, pathname)

    if (!match) {
      return createErrorResponse(
        ErrorCodes.RESOURCE_NOT_FOUND,
        `Route not found: ${method} ${pathname}`,
        404
      )
    }

    try {
      return await match.route.handler(req, match.params)
    } catch (error) {
      console.error('Route handler error:', error)
      return createErrorResponse(
        ErrorCodes.INTERNAL_SERVER_ERROR,
        'Internal server error',
        500
      )
    }
  }

  // Utility methods
  getRoutes(): Route[] {
    return [...this.routes]
  }

  use(path: string, router: APIRouter) {
    const subRoutes = router.getRoutes()
    for (const route of subRoutes) {
      const newPath = path + (route.path instanceof RegExp ? route.path.source : route.path)
      this.routes.push({
        ...route,
        path: this.normalizePath(newPath)
      })
    }
  }
}

// Helper function to create route groups
export function createRouteGroup(basePath: string = ''): APIRouter {
  return new APIRouter(basePath)
}

// Common route patterns
export const routePatterns = {
  uuid: /[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i,
  id: /\d+/,
  slug: /[a-z0-9-]+/,
  version: /v\d+/
}

// Route parameter validation
export function validateRouteParams(params: Record<string, string>, schema: Record<string, RegExp>): boolean {
  for (const [key, pattern] of Object.entries(schema)) {
    if (params[key] && !pattern.test(params[key])) {
      return false
    }
  }
  return true
}