import { Env } from './types';
import { authenticateRequest } from './middleware/auth';
import { handleAuthRoutes } from './routes/auth';
import { handlePhotoRoutes } from './routes/photos';
import { handleWorkoutRoutes } from './routes/workouts';
import { handleMeasurementRoutes } from './routes/measurements';
import { handleAnalyticsRoutes } from './routes/analytics';

function getCorsHeaders(request: Request): Headers {
  const headers = new Headers();
  const origin = request.headers.get('Origin') || '*';
  headers.set('Access-Control-Allow-Origin', origin);
  headers.set('Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT, DELETE, OPTIONS');
  headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  headers.set('Access-Control-Max-Age', '86400');
  return headers;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const corsHeaders = getCorsHeaders(request);

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders, status: 204 });
    }

    try {
      const url = new URL(request.url);
      const path = url.pathname;

      // Extract authenticated user if Bearer token present
      const user = await authenticateRequest(request, env);

      let response: Response;

      if (path.startsWith('/api/auth')) {
        response = await handleAuthRoutes(request, env, url, user);
      } else if (path.startsWith('/api/photos')) {
        response = await handlePhotoRoutes(request, env, url, user);
      } else if (path.startsWith('/api/workouts')) {
        response = await handleWorkoutRoutes(request, env, url, user);
      } else if (path.startsWith('/api/measurements')) {
        response = await handleMeasurementRoutes(request, env, url, user);
      } else if (path.startsWith('/api/analytics')) {
        response = await handleAnalyticsRoutes(request, env, url, user);
      } else if (path === '/' || path === '/health') {
        response = Response.json({ success: true, data: { status: 'healthy', service: 'fittrack-api' } });
      } else {
        response = Response.json(
          { success: false, error: { code: 'NOT_FOUND', message: 'API endpoint not found.' } },
          { status: 404 }
        );
      }

      // Merge CORS headers into response
      const newHeaders = new Headers(response.headers);
      corsHeaders.forEach((value, key) => {
        newHeaders.set(key, value);
      });

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: newHeaders,
      });
    } catch (error: any) {
      const errHeaders = getCorsHeaders(request);
      errHeaders.set('Content-Type', 'application/json');
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INTERNAL_ERROR',
            message: error?.message || 'An unexpected error occurred.',
          },
        }),
        { status: 500, headers: errHeaders }
      );
    }
  },
};
