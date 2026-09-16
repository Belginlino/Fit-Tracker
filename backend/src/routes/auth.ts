import { Env, AuthUser } from '../types';
import { hashPassword, verifyPassword, signJwt } from '../utils/crypto';

export async function handleAuthRoutes(
  request: Request,
  env: Env,
  url: URL,
  user: AuthUser | null
): Promise<Response> {
  const method = request.method;
  const path = url.pathname;

  // POST /api/auth/register
  if (path === '/api/auth/register' && method === 'POST') {
    const body = await request.json() as any;
    const { email, password, name } = body;

    if (!email || !password || !name) {
      return Response.json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'Email, password, and name are required.' } }, { status: 400 });
    }

    // Check existing
    const existing = await env.DB.prepare('SELECT id FROM users WHERE email = ?').bind(email.toLowerCase()).first();
    if (existing) {
      return Response.json({ success: false, error: { code: 'AUTH_EMAIL_IN_USE', message: 'An account with this email already exists.' } }, { status: 400 });
    }

    const userId = `u-${crypto.randomUUID()}`;
    const passwordHash = await hashPassword(password);

    await env.DB.prepare(`
      INSERT INTO users (id, email, password_hash, name, has_completed_onboarding)
      VALUES (?, ?, ?, ?, 0)
    `).bind(userId, email.toLowerCase(), passwordHash, name).run();

    const token = await signJwt({ id: userId, email: email.toLowerCase(), name }, env.JWT_SECRET);

    const userProfile = {
      id: userId,
      email: email.toLowerCase(),
      name,
      goal: 'Build Muscle',
      currentWeight: 74.2,
      targetWeight: 78.0,
      height: 178.0,
      preferredWorkoutDays: ['Mon', 'Tue', 'Thu', 'Fri'],
      reminderTime: '18:30',
      workoutStreak: 0,
      photoStreak: 0,
      hasCompletedOnboarding: false,
    };

    return Response.json({ success: true, data: { token, user: userProfile } });
  }

  // POST /api/auth/login
  if (path === '/api/auth/login' && method === 'POST') {
    const body = await request.json() as any;
    const { email, password } = body;

    if (!email || !password) {
      return Response.json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'Email and password required.' } }, { status: 400 });
    }

    const userRow = await env.DB.prepare('SELECT * FROM users WHERE email = ?').bind(email.toLowerCase()).first() as any;
    if (!userRow) {
      return Response.json({ success: false, error: { code: 'AUTH_INVALID_CREDENTIALS', message: 'Invalid email or password.' } }, { status: 401 });
    }

    const isValid = await verifyPassword(password, userRow.password_hash);
    if (!isValid) {
      return Response.json({ success: false, error: { code: 'AUTH_INVALID_CREDENTIALS', message: 'Invalid email or password.' } }, { status: 401 });
    }

    const token = await signJwt({ id: userRow.id, email: userRow.email, name: userRow.name }, env.JWT_SECRET);

    let preferredDays = ['Mon', 'Tue', 'Thu', 'Fri'];
    try {
      if (userRow.preferred_days) preferredDays = JSON.parse(userRow.preferred_days);
    } catch {}

    const userProfile = {
      id: userRow.id,
      email: userRow.email,
      name: userRow.name,
      goal: userRow.goal ?? 'Build Muscle',
      currentWeight: userRow.current_weight ?? 74.2,
      targetWeight: userRow.target_weight ?? 78.0,
      height: userRow.height ?? 178.0,
      preferredWorkoutDays: preferredDays,
      reminderTime: userRow.reminder_time ?? '18:30',
      workoutStreak: userRow.workout_streak ?? 0,
      photoStreak: userRow.photo_streak ?? 0,
      hasCompletedOnboarding: userRow.has_completed_onboarding === 1,
    };

    return Response.json({ success: true, data: { token, user: userProfile } });
  }

  // Authenticated routes below
  if (!user) {
    return Response.json({ success: false, error: { code: 'AUTH_UNAUTHORIZED', message: 'Authentication required.' } }, { status: 401 });
  }

  // GET /api/auth/me
  if (path === '/api/auth/me' && method === 'GET') {
    const userRow = await env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(user.id).first() as any;
    if (!userRow) {
      return Response.json({ success: false, error: { code: 'USER_NOT_FOUND', message: 'User not found.' } }, { status: 404 });
    }

    let preferredDays = ['Mon', 'Tue', 'Thu', 'Fri'];
    try {
      if (userRow.preferred_days) preferredDays = JSON.parse(userRow.preferred_days);
    } catch {}

    const userProfile = {
      id: userRow.id,
      email: userRow.email,
      name: userRow.name,
      goal: userRow.goal ?? 'Build Muscle',
      currentWeight: userRow.current_weight ?? 74.2,
      targetWeight: userRow.target_weight ?? 78.0,
      height: userRow.height ?? 178.0,
      preferredWorkoutDays: preferredDays,
      reminderTime: userRow.reminder_time ?? '18:30',
      workoutStreak: userRow.workout_streak ?? 0,
      photoStreak: userRow.photo_streak ?? 0,
      hasCompletedOnboarding: userRow.has_completed_onboarding === 1,
    };

    return Response.json({ success: true, data: userProfile });
  }

  // PATCH /api/auth/profile
  if (path === '/api/auth/profile' && method === 'PATCH') {
    const body = await request.json() as any;
    const { name, goal, currentWeight, targetWeight, height, preferredWorkoutDays, reminderTime, hasCompletedOnboarding } = body;

    await env.DB.prepare(`
      UPDATE users SET
        name = COALESCE(?, name),
        goal = COALESCE(?, goal),
        current_weight = COALESCE(?, current_weight),
        target_weight = COALESCE(?, target_weight),
        height = COALESCE(?, height),
        preferred_days = COALESCE(?, preferred_days),
        reminder_time = COALESCE(?, reminder_time),
        has_completed_onboarding = COALESCE(?, has_completed_onboarding),
        updated_at = datetime('now')
      WHERE id = ?
    `).bind(
      name ?? null,
      goal ?? null,
      currentWeight ?? null,
      targetWeight ?? null,
      height ?? null,
      preferredWorkoutDays ? JSON.stringify(preferredWorkoutDays) : null,
      reminderTime ?? null,
      hasCompletedOnboarding !== undefined ? (hasCompletedOnboarding ? 1 : 0) : null,
      user.id
    ).run();

    return Response.json({ success: true, data: { message: 'Profile updated successfully.' } });
  }

  // DELETE /api/auth/delete-account (Purges user data and R2 objects per Section 32 & 703)
  if (path === '/api/auth/delete-account' && method === 'DELETE') {
    // List all user photos in R2 to delete
    const photos = await env.DB.prepare('SELECT r2_object_key FROM progress_photos WHERE user_id = ?').bind(user.id).all();
    if (photos.results && photos.results.length > 0) {
      for (const row of photos.results) {
        if (row.r2_object_key) {
          await env.PHOTOS_BUCKET.delete(row.r2_object_key as string);
        }
      }
    }

    // Delete user from D1 (CASCADE deletes workouts, sets, measurements, photos)
    await env.DB.prepare('DELETE FROM users WHERE id = ?').bind(user.id).run();

    return Response.json({ success: true, data: { message: 'Account and associated records permanently deleted.' } });
  }

  return Response.json({ success: false, error: { code: 'NOT_FOUND', message: 'Route not found.' } }, { status: 404 });
}
