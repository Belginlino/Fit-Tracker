import { Env, AuthUser } from '../types';
import { verifyJwt } from '../utils/crypto';

export async function authenticateRequest(request: Request, env: Env): Promise<AuthUser | null> {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  const token = authHeader.substring(7);
  const payload = await verifyJwt<{ id: string; email: string; name: string }>(token, env.JWT_SECRET);
  if (!payload || !payload.id) {
    return null;
  }

  return {
    id: payload.id,
    email: payload.email,
    name: payload.name,
  };
}
