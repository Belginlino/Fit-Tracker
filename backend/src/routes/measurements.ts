import { Env, AuthUser } from '../types';

export async function handleMeasurementRoutes(
  request: Request,
  env: Env,
  url: URL,
  user: AuthUser | null
): Promise<Response> {
  if (!user) {
    return Response.json({ success: false, error: { code: 'AUTH_UNAUTHORIZED', message: 'Authentication required.' } }, { status: 401 });
  }

  const method = request.method;
  const path = url.pathname;

  // GET /api/measurements
  if (path === '/api/measurements' && method === 'GET') {
    const type = url.searchParams.get('type');
    let query = 'SELECT * FROM measurements WHERE user_id = ?';
    const params: any[] = [user.id];

    if (type) {
      query += ' AND type = ?';
      params.push(type);
    }
    query += ' ORDER BY recorded_at DESC';

    const result = await env.DB.prepare(query).bind(...params).all();
    const measurements = (result.results || []).map((row: any) => ({
      id: row.id,
      userId: row.user_id,
      type: row.type,
      value: row.value,
      unit: row.unit,
      recordedAt: row.recorded_at,
      note: row.note,
    }));

    return Response.json({ success: true, data: measurements });
  }

  // POST /api/measurements
  if (path === '/api/measurements' && method === 'POST') {
    const body = await request.json() as any;
    const { id, type, value, unit, recordedAt, note } = body;

    const measurementId = id || `m-${Date.now()}`;
    const date = recordedAt || new Date().toISOString();

    await env.DB.prepare(`
      INSERT INTO measurements (id, user_id, type, value, unit, note, recorded_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(measurementId, user.id, type || 'Weight', value || 0, unit || 'kg', note || null, date).run();

    // If weight, update current_weight on user profile
    if (type === 'Weight' && value) {
      await env.DB.prepare('UPDATE users SET current_weight = ? WHERE id = ?').bind(value, user.id).run();
    }

    return Response.json({
      success: true,
      data: {
        id: measurementId,
        userId: user.id,
        type: type || 'Weight',
        value,
        unit: unit || 'kg',
        recordedAt: date,
        note,
      },
    });
  }

  // DELETE /api/measurements/:id
  const deleteMatch = path.match(/^\/api\/measurements\/([^/]+)$/);
  if (deleteMatch && method === 'DELETE') {
    const measurementId = deleteMatch[1];
    await env.DB.prepare('DELETE FROM measurements WHERE id = ? AND user_id = ?').bind(measurementId, user.id).run();
    return Response.json({ success: true, data: { message: 'Measurement deleted.' } });
  }

  return Response.json({ success: false, error: { code: 'NOT_FOUND', message: 'Route not found.' } }, { status: 404 });
}
