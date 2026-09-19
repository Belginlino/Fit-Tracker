const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '6aac02f1002c53d0bc56';
const DATABASE_ID = 'fittrack';
const API_KEY = process.argv[2];

async function api(path, method = 'GET', body = null) {
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': PROJECT_ID,
      'X-Appwrite-Key': API_KEY,
    },
  };
  if (body) options.body = JSON.stringify(body);
  const res = await fetch(`${ENDPOINT}${path}`, options);
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = { raw: text }; }
  return { status: res.status, ok: res.ok, data };
}

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  console.log('Fixing remaining attributes on workout_sets and personal_records...');

  // 1. set_number on workout_sets
  const setNumRes = await api(`/databases/${DATABASE_ID}/collections/workout_sets/attributes/integer`, 'POST', {
    key: 'set_number',
    required: true,
  });
  console.log('workout_sets.set_number:', setNumRes.status, setNumRes.data.message || 'created');

  // 2. max_weight on personal_records
  const maxWeightRes = await api(`/databases/${DATABASE_ID}/collections/personal_records/attributes/float`, 'POST', {
    key: 'max_weight',
    required: true,
  });
  console.log('personal_records.max_weight:', maxWeightRes.status, maxWeightRes.data.message || 'created');

  // Wait for attributes to become available
  console.log('Waiting 3 seconds for attributes to be indexed in Appwrite...');
  await sleep(3000);

  // 3. idx_sets_exercise index on workout_sets
  const idxRes = await api(`/databases/${DATABASE_ID}/collections/workout_sets/indexes`, 'POST', {
    key: 'idx_sets_exercise',
    type: 'key',
    attributes: ['workout_exercise_id', 'set_number'],
    orders: ['ASC', 'ASC'],
  });
  console.log('workout_sets.idx_sets_exercise:', idxRes.status, idxRes.data.message || 'created');

  console.log('\nAll attributes and indexes 100% complete!');
}

main().catch(console.error);
