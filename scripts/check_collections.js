const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '6aac02f1002c53d0bc56';
const DATABASE_ID = 'fittrack';

const collections = [
  'profiles',
  'workouts',
  'workout_exercises',
  'workout_sets',
  'personal_records',
  'measurements',
  'progress_photos',
];

async function check() {
  for (const c of collections) {
    const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/${c}/documents`, {
      headers: {
        'X-Appwrite-Project': PROJECT_ID,
      },
    });
    const text = await res.text();
    let json;
    try { json = JSON.parse(text); } catch { json = text; }
    if (res.ok) {
      console.log(`[EXISTS] ${c} - Status: ${res.status}`);
    } else {
      console.log(`[FAILED] ${c} - Status: ${res.status} - ${json.message || text}`);
    }
  }
}

check().catch(console.error);
