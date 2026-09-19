/**
 * FitTrack - Appwrite Database & Storage Setup Script
 *
 * Automatically creates the `fittrack` database, all 7 collections,
 * all attributes, indexes, and storage bucket on Appwrite Cloud or Self-Hosted.
 *
 * Usage:
 *   node scripts/setup_appwrite.js <YOUR_APPWRITE_API_KEY>
 *
 * Or set environment variable:
 *   APPWRITE_API_KEY=your_key node scripts/setup_appwrite.js
 */

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || '6aac02f1002c53d0bc56';
const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'fittrack';
const BUCKET_ID = process.env.APPWRITE_PHOTOS_BUCKET || 'progress-photos';
const API_KEY = process.argv[2] || process.env.APPWRITE_API_KEY;

if (!API_KEY) {
  console.log(`
================================================================
  FitTrack Appwrite Database Setup
================================================================
  Please provide your Appwrite API Key to provision collections.

  How to get an Appwrite API Key:
  1. Open Appwrite Console: https://cloud.appwrite.io/console/project/${PROJECT_ID}
  2. Go to: Overview > Integrations > API Keys (or Project Settings > API Keys)
  3. Click "Create API Key"
  4. Name: "FitTrack Setup", Expiration: None / Desired
  5. Scopes: Check "databases.write", "collections.write", "attributes.write", "indexes.write", "buckets.write"
  6. Copy the generated secret key and run:

     node scripts/setup_appwrite.js <YOUR_API_KEY>
================================================================
`);
  process.exit(1);
}

const headers = {
  'Content-Type': 'application/json',
  'X-Appwrite-Project': PROJECT_ID,
  'X-Appwrite-Key': API_KEY,
};

async function api(path, method = 'GET', body = null) {
  const options = { method, headers };
  if (body) options.body = JSON.stringify(body);
  const res = await fetch(`${ENDPOINT}${path}`, options);
  const text = await res.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    data = { raw: text };
  }
  return { status: res.status, ok: res.ok, data };
}

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  console.log(`Connecting to Appwrite: ${ENDPOINT} (Project: ${PROJECT_ID})`);

  // 1. Create Database
  console.log(`\n[1/8] Ensuring database '${DATABASE_ID}' exists...`);
  const dbRes = await api('/databases', 'POST', {
    databaseId: DATABASE_ID,
    name: 'FitTrack Database',
    enabled: true,
  });
  if (dbRes.ok) {
    console.log(`  ✓ Database '${DATABASE_ID}' created.`);
  } else if (dbRes.status === 409) {
    console.log(`  ✓ Database '${DATABASE_ID}' already exists.`);
  } else {
    console.log(`  Note on database: ${dbRes.data.message || dbRes.status}`);
  }

  // 2. Collections definition
  const collections = [
    {
      id: 'profiles',
      name: 'User Profiles',
      attributes: [
        { key: 'name', type: 'string', size: 128, required: false, default: 'Athlete' },
        { key: 'goal', type: 'string', size: 64, required: false, default: 'Build Muscle' },
        { key: 'height', type: 'float', required: false, default: 178.0 },
        { key: 'current_weight', type: 'float', required: false, default: 74.2 },
        { key: 'target_weight', type: 'float', required: false, default: 78.0 },
        { key: 'preferred_reminder_time', type: 'string', size: 16, required: false, default: '18:00:00' },
        { key: 'workout_streak', type: 'integer', required: false, default: 0 },
        { key: 'photo_streak', type: 'integer', required: false, default: 0 },
        { key: 'has_completed_onboarding', type: 'boolean', required: false, default: false },
      ],
      indexes: [],
    },
    {
      id: 'workouts',
      name: 'Workouts',
      attributes: [
        { key: 'user_id', type: 'string', size: 64, required: true },
        { key: 'title', type: 'string', size: 128, required: true },
        { key: 'workout_date', type: 'string', size: 64, required: true },
        { key: 'duration_minutes', type: 'integer', required: false, default: 45 },
        { key: 'notes', type: 'string', size: 2048, required: false },
      ],
      indexes: [
        { key: 'idx_workouts_user_date', type: 'key', attributes: ['user_id', 'workout_date'], orders: ['ASC', 'DESC'] },
      ],
    },
    {
      id: 'workout_exercises',
      name: 'Workout Exercises',
      attributes: [
        { key: 'workout_id', type: 'string', size: 64, required: true },
        { key: 'user_id', type: 'string', size: 64, required: true },
        { key: 'exercise_name', type: 'string', size: 128, required: true },
        { key: 'exercise_order', type: 'integer', required: false, default: 0 },
        { key: 'notes', type: 'string', size: 1024, required: false },
      ],
      indexes: [
        { key: 'idx_exercises_workout', type: 'key', attributes: ['workout_id', 'exercise_order'], orders: ['ASC', 'ASC'] },
      ],
    },
    {
      id: 'workout_sets',
      name: 'Workout Sets',
      attributes: [
        { key: 'workout_id', type: 'string', size: 64, required: true },
        { key: 'workout_exercise_id', type: 'string', size: 64, required: true },
        { key: 'user_id', type: 'string', size: 64, required: true },
        { key: 'set_number', type: 'integer', required: true, default: 1 },
        { key: 'weight', type: 'float', required: false, default: 0.0 },
        { key: 'reps', type: 'integer', required: false, default: 0 },
        { key: 'is_completed', type: 'boolean', required: false, default: true },
      ],
      indexes: [
        { key: 'idx_sets_exercise', type: 'key', attributes: ['workout_exercise_id', 'set_number'], orders: ['ASC', 'ASC'] },
      ],
    },
    {
      id: 'personal_records',
      name: 'Personal Records',
      attributes: [
        { key: 'user_id', type: 'string', size: 64, required: true },
        { key: 'exercise_name', type: 'string', size: 128, required: true },
        { key: 'max_weight', type: 'float', required: true, default: 0.0 },
        { key: 'max_reps', type: 'integer', required: false, default: 0 },
        { key: 'achieved_at', type: 'string', size: 64, required: false },
        { key: 'workout_id', type: 'string', size: 64, required: false },
      ],
      indexes: [
        { key: 'idx_pr_user_exercise', type: 'key', attributes: ['user_id', 'exercise_name'], orders: ['ASC', 'ASC'] },
      ],
    },
    {
      id: 'measurements',
      name: 'Body Measurements',
      attributes: [
        { key: 'user_id', type: 'string', size: 64, required: true },
        { key: 'measurement_type', type: 'string', size: 64, required: true },
        { key: 'value', type: 'float', required: true },
        { key: 'unit', type: 'string', size: 16, required: false, default: 'kg' },
        { key: 'recorded_at', type: 'string', size: 64, required: true },
        { key: 'notes', type: 'string', size: 1024, required: false },
      ],
      indexes: [
        { key: 'idx_measurements_user_type_date', type: 'key', attributes: ['user_id', 'measurement_type', 'recorded_at'], orders: ['ASC', 'ASC', 'DESC'] },
      ],
    },
    {
      id: 'progress_photos',
      name: 'Progress Photos',
      attributes: [
        { key: 'user_id', type: 'string', size: 64, required: true },
        { key: 'file_id', type: 'string', size: 64, required: true },
        { key: 'storage_path', type: 'string', size: 128, required: false },
        { key: 'pose', type: 'string', size: 64, required: false, default: 'Front' },
        { key: 'workout_id', type: 'string', size: 64, required: false },
        { key: 'weight_at_capture', type: 'float', required: false },
        { key: 'notes', type: 'string', size: 2048, required: false },
        { key: 'day_number', type: 'integer', required: false, default: 1 },
        { key: 'created_at', type: 'string', size: 64, required: true },
      ],
      indexes: [
        { key: 'idx_photos_user_date', type: 'key', attributes: ['user_id', 'created_at'], orders: ['ASC', 'DESC'] },
        { key: 'idx_photos_user_day', type: 'key', attributes: ['user_id', 'day_number'], orders: ['ASC', 'ASC'] },
      ],
    },
  ];

  for (let i = 0; i < collections.length; i++) {
    const col = collections[i];
    console.log(`\n[${i + 2}/8] Creating collection '${col.id}' (${col.name})...`);

    const colRes = await api(`/databases/${DATABASE_ID}/collections`, 'POST', {
      collectionId: col.id,
      name: col.name,
      permissions: ['read("any")', 'create("any")', 'update("any")', 'delete("any")'],
      documentSecurity: false,
      enabled: true,
    });

    if (colRes.ok) {
      console.log(`  ✓ Collection '${col.id}' created.`);
    } else if (colRes.status === 409) {
      console.log(`  ✓ Collection '${col.id}' already exists.`);
    } else {
      console.log(`  Note on collection: ${colRes.data.message || colRes.status}`);
    }

    // Create attributes
    for (const attr of col.attributes) {
      const path = `/databases/${DATABASE_ID}/collections/${col.id}/attributes/${attr.type}`;
      const payload = {
        key: attr.key,
        required: attr.required,
      };
      if (attr.type === 'string') payload.size = attr.size || 128;
      if (attr.default !== undefined) payload.default = attr.default;

      const attrRes = await api(path, 'POST', payload);
      if (attrRes.ok) {
        console.log(`    + Attribute '${attr.key}' (${attr.type}) created.`);
      } else if (attrRes.status === 409) {
        console.log(`    + Attribute '${attr.key}' exists.`);
      } else {
        console.log(`    ! Attribute '${attr.key}': ${attrRes.data.message || attrRes.status}`);
      }
      await sleep(150);
    }

    // Wait for attributes to become available before adding indexes
    if (col.indexes.length > 0) {
      await sleep(1000);
      for (const idx of col.indexes) {
        const idxRes = await api(`/databases/${DATABASE_ID}/collections/${col.id}/indexes`, 'POST', {
          key: idx.key,
          type: idx.type,
          attributes: idx.attributes,
          orders: idx.orders,
        });
        if (idxRes.ok) {
          console.log(`    # Index '${idx.key}' created.`);
        } else if (idxRes.status === 409) {
          console.log(`    # Index '${idx.key}' exists.`);
        } else {
          console.log(`    ! Index '${idx.key}': ${idxRes.data.message || idxRes.status}`);
        }
        await sleep(150);
      }
    }
  }

  // 8. Storage Bucket
  console.log(`\n[8/8] Ensuring storage bucket '${BUCKET_ID}' exists...`);
  const bucketRes = await api('/storage/buckets', 'POST', {
    bucketId: BUCKET_ID,
    name: 'Progress Photos',
    permissions: ['read("any")', 'create("any")', 'update("any")', 'delete("any")'],
    fileSecurity: false,
    enabled: true,
    maximumFileSize: 15 * 1024 * 1024,
    allowedFileExtensions: ['jpg', 'jpeg', 'png', 'webp', 'json'],
  });

  if (bucketRes.ok) {
    console.log(`  ✓ Storage bucket '${BUCKET_ID}' created.`);
  } else if (bucketRes.status === 409) {
    console.log(`  ✓ Storage bucket '${BUCKET_ID}' already exists.`);
  } else {
    console.log(`  Note on storage bucket: ${bucketRes.data.message || bucketRes.status}`);
  }

  console.log(`
================================================================
  ✓ All FitTrack database collections and storage initialized!
================================================================
`);
}

main().catch((err) => {
  console.error('Fatal error during setup:', err);
  process.exit(1);
});
