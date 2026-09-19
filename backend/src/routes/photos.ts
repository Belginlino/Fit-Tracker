import { Env, AuthUser } from '../types';

export async function handlePhotoRoutes(
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

  // GET /api/photos - List photos for authenticated user
  if (path === '/api/photos' && method === 'GET') {
    const pose = url.searchParams.get('pose');
    let query = 'SELECT * FROM progress_photos WHERE user_id = ?';
    const params: any[] = [user.id];

    if (pose && pose !== 'All') {
      query += ' AND pose = ?';
      params.push(pose);
    }
    query += ' ORDER BY created_at DESC';

    const result = await env.DB.prepare(query).bind(...params).all();
    const photos = (result.results || []).map((row: any) => ({
      id: row.id,
      userId: row.user_id,
      storagePath: row.r2_object_key,
      downloadUrl: `/api/photos/${row.id}/content`,
      pose: row.pose,
      workoutId: row.workout_id,
      weightAtCapture: row.weight_at_capture,
      notes: row.notes,
      dayNumber: row.day_number ?? 1,
      createdAt: row.created_at,
    }));

    return Response.json({ success: true, data: photos });
  }

  // POST /api/photos/upload - Direct binary stream upload into R2
  if (path === '/api/photos/upload' && method === 'POST') {
    const contentType = request.headers.get('content-type') || 'image/jpeg';
    if (!contentType.startsWith('image/')) {
      return Response.json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'Only image files are allowed.' } }, { status: 400 });
    }

    const photoId = `photo-${Date.now()}-${crypto.randomUUID().slice(0, 8)}`;
    const objectKey = `users/${user.id}/progress/${photoId}.jpg`;

    const imageBytes = await request.arrayBuffer();
    if (imageBytes.byteLength > 15 * 1024 * 1024) {
      return Response.json({ success: false, error: { code: 'FILE_TOO_LARGE', message: 'Image size exceeds 15MB.' } }, { status: 400 });
    }

    // Write directly into private R2 bucket binding
    await env.PHOTOS_BUCKET.put(objectKey, imageBytes, {
      httpMetadata: { contentType },
      customMetadata: { userId: user.id, photoId },
    });

    return Response.json({
      success: true,
      data: {
        photoId,
        objectKey,
      },
    });
  }

  // POST /api/photos - Record photo metadata in D1
  if (path === '/api/photos' && method === 'POST') {
    const body = await request.json() as any;
    const { id, objectKey, pose, workoutId, weightAtCapture, notes, dayNumber, createdAt } = body;

    const photoId = id || `photo-${Date.now()}`;
    const key = objectKey || `users/${user.id}/progress/${photoId}.jpg`;
    const photoDay = dayNumber ? Number(dayNumber) : 1;
    const photoDate = createdAt || new Date().toISOString();

    await env.DB.prepare(`
      INSERT INTO progress_photos (id, user_id, r2_object_key, pose, workout_id, weight_at_capture, notes, day_number, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      photoId,
      user.id,
      key,
      pose || 'Front',
      workoutId || null,
      weightAtCapture || null,
      notes || null,
      photoDay,
      photoDate
    ).run();

    // Increment user photo streak
    await env.DB.prepare(`
      UPDATE users SET photo_streak = photo_streak + 1 WHERE id = ?
    `).bind(user.id).run();

    return Response.json({
      success: true,
      data: {
        id: photoId,
        userId: user.id,
        storagePath: key,
        downloadUrl: `/api/photos/${photoId}/content`,
        pose: pose || 'Front',
        weightAtCapture,
        notes,
        dayNumber: photoDay,
        createdAt: photoDate,
      },
    });
  }

  // GET /api/photos/:id/content - Stream authorized photo binary from R2
  const contentMatch = path.match(/^\/api\/photos\/([^/]+)\/content$/);
  if (contentMatch && method === 'GET') {
    const photoId = contentMatch[1];
    const photoRow = await env.DB.prepare('SELECT * FROM progress_photos WHERE id = ?').bind(photoId).first() as any;

    if (!photoRow) {
      return Response.json({ success: false, error: { code: 'PHOTO_NOT_FOUND', message: 'Photo not found.' } }, { status: 404 });
    }

    // Enforce strict ownership check (Section 180)
    if (photoRow.user_id !== user.id) {
      return Response.json({ success: false, error: { code: 'FORBIDDEN', message: 'Access denied.' } }, { status: 403 });
    }

    const object = await env.PHOTOS_BUCKET.get(photoRow.r2_object_key);
    if (!object) {
      return new Response('Not Found', { status: 404 });
    }

    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set('etag', object.httpEtag);
    headers.set('Cache-Control', 'private, max-age=3600');

    return new Response(object.body, { headers });
  }

  // DELETE /api/photos/:id
  const deleteMatch = path.match(/^\/api\/photos\/([^/]+)$/);
  if (deleteMatch && method === 'DELETE') {
    const photoId = deleteMatch[1];
    const photoRow = await env.DB.prepare('SELECT * FROM progress_photos WHERE id = ?').bind(photoId).first() as any;

    if (!photoRow || photoRow.user_id !== user.id) {
      return Response.json({ success: false, error: { code: 'PHOTO_NOT_FOUND', message: 'Photo not found or unauthorized.' } }, { status: 404 });
    }

    await env.PHOTOS_BUCKET.delete(photoRow.r2_object_key);
    await env.DB.prepare('DELETE FROM progress_photos WHERE id = ?').bind(photoId).run();

    return Response.json({ success: true, data: { message: 'Photo deleted successfully.' } });
  }

  return Response.json({ success: false, error: { code: 'NOT_FOUND', message: 'Route not found.' } }, { status: 404 });
}
