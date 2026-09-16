import { Env, AuthUser } from '../types';

export async function handleWorkoutRoutes(
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

  // GET /api/workouts
  if (path === '/api/workouts' && method === 'GET') {
    const workoutsRes = await env.DB.prepare(
      'SELECT * FROM workouts WHERE user_id = ? ORDER BY date DESC'
    ).bind(user.id).all();

    const workouts = [];
    for (const w of (workoutsRes.results || []) as any[]) {
      const exercisesRes = await env.DB.prepare(
        'SELECT * FROM workout_exercises WHERE workout_id = ? ORDER BY exercise_order ASC'
      ).bind(w.id).all();

      const exercises = [];
      for (const ex of (exercisesRes.results || []) as any[]) {
        const setsRes = await env.DB.prepare(
          'SELECT * FROM workout_sets WHERE exercise_id = ? ORDER BY set_number ASC'
        ).bind(ex.id).all();

        exercises.push({
          name: ex.name,
          notes: ex.notes,
          sets: (setsRes.results || []).map((s: any) => ({
            setNumber: s.set_number,
            weight: s.weight,
            reps: s.reps,
            isCompleted: s.is_completed === 1,
          })),
        });
      }

      workouts.push({
        id: w.id,
        userId: w.user_id,
        title: w.title,
        date: w.date,
        durationMinutes: w.duration_minutes,
        notes: w.notes,
        exercises,
      });
    }

    return Response.json({ success: true, data: workouts });
  }

  // POST /api/workouts
  if (path === '/api/workouts' && method === 'POST') {
    const body = await request.json() as any;
    const { id, title, date, durationMinutes, exercises, notes } = body;

    const workoutId = id || `workout-${Date.now()}`;
    const workoutDate = date || new Date().toISOString();

    // 1. Insert Workout
    await env.DB.prepare(`
      INSERT INTO workouts (id, user_id, title, date, duration_minutes, notes)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(workoutId, user.id, title || 'Workout', workoutDate, durationMinutes || 45, notes || null).run();

    // 2. Insert Exercises and Sets
    if (Array.isArray(exercises)) {
      for (let i = 0; i < exercises.length; i++) {
        const ex = exercises[i];
        const exerciseId = `ex-${Date.now()}-${i}`;

        await env.DB.prepare(`
          INSERT INTO workout_exercises (id, workout_id, name, exercise_order, notes)
          VALUES (?, ?, ?, ?, ?)
        `).bind(exerciseId, workoutId, ex.name, i, ex.notes || null).run();

        let maxWeightForEx = 0;
        if (Array.isArray(ex.sets)) {
          for (const set of ex.sets) {
            const setId = `set-${Date.now()}-${crypto.randomUUID().slice(0, 6)}`;
            await env.DB.prepare(`
              INSERT INTO workout_sets (id, exercise_id, set_number, weight, reps, is_completed)
              VALUES (?, ?, ?, ?, ?, ?)
            `).bind(setId, exerciseId, set.setNumber, set.weight || 0, set.reps || 0, set.isCompleted ? 1 : 0).run();

            if (set.weight && set.weight > maxWeightForEx) {
              maxWeightForEx = set.weight;
            }
          }
        }

        // 3. Auto-update Personal Records in D1
        if (maxWeightForEx > 0) {
          const currentPr = await env.DB.prepare(
            'SELECT max_weight FROM personal_records WHERE user_id = ? AND exercise_name = ?'
          ).bind(user.id, ex.name).first() as any;

          if (!currentPr) {
            await env.DB.prepare(`
              INSERT INTO personal_records (id, user_id, exercise_name, max_weight, workout_id)
              VALUES (?, ?, ?, ?, ?)
            `).bind(`pr-${Date.now()}`, user.id, ex.name, maxWeightForEx, workoutId).run();
          } else if (maxWeightForEx > currentPr.max_weight) {
            await env.DB.prepare(`
              UPDATE personal_records SET max_weight = ?, achieved_at = datetime('now'), workout_id = ?
              WHERE user_id = ? AND exercise_name = ?
            `).bind(maxWeightForEx, workoutId, user.id, ex.name).run();
          }
        }
      }
    }

    // 4. Increment user workout streak
    await env.DB.prepare(`
      UPDATE users SET workout_streak = workout_streak + 1 WHERE id = ?
    `).bind(user.id).run();

    return Response.json({
      success: true,
      data: {
        id: workoutId,
        userId: user.id,
        title,
        date: workoutDate,
        durationMinutes: durationMinutes || 45,
        exercises: exercises || [],
        notes,
      },
    });
  }

  // DELETE /api/workouts/:id
  const deleteMatch = path.match(/^\/api\/workouts\/([^/]+)$/);
  if (deleteMatch && method === 'DELETE') {
    const workoutId = deleteMatch[1];
    await env.DB.prepare('DELETE FROM workouts WHERE id = ? AND user_id = ?').bind(workoutId, user.id).run();
    return Response.json({ success: true, data: { message: 'Workout deleted.' } });
  }

  return Response.json({ success: false, error: { code: 'NOT_FOUND', message: 'Route not found.' } }, { status: 404 });
}
