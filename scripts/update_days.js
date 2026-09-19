const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '6aac02f1002c53d0bc56';
const USER_ID = '6aac069ce6f50648c106';
const API_KEY = process.argv[2];

if (!API_KEY) {
  console.log('API key required');
  process.exit(1);
}

const manifest = [
  {
    id: 'photo-1789755644834',
    storagePath: '6aad80fccd9a852e7659',
    downloadUrl: `${ENDPOINT}/storage/buckets/progress-photos/files/6aad80fccd9a852e7659/view?project=${PROJECT_ID}`,
    dayNumber: 1,
    createdAt: '2026-09-18T23:50:44.834',
    pose: 'Front',
    weightAtCapture: null,
    notes: '[Day 1]',
    workoutId: null,
  },
  {
    id: 'photo-1789820869738',
    storagePath: '6aae7fc5b65044c9fdea',
    downloadUrl: `${ENDPOINT}/storage/buckets/progress-photos/files/6aae7fc5b65044c9fdea/view?project=${PROJECT_ID}`,
    dayNumber: 2,
    createdAt: '2026-09-19T17:57:49.738',
    pose: 'Front',
    weightAtCapture: null,
    notes: '[Day 2]',
    workoutId: null,
  },
  {
    id: 'photo-1789821022893',
    storagePath: '6aae805edc3b25dc957e',
    downloadUrl: `${ENDPOINT}/storage/buckets/progress-photos/files/6aae805edc3b25dc957e/view?project=${PROJECT_ID}`,
    dayNumber: 3,
    createdAt: '2026-09-19T18:00:22.893',
    pose: 'Front',
    weightAtCapture: null,
    notes: '[Day 3]',
    workoutId: null,
  },
  {
    id: 'photo-1789821168033',
    storagePath: '6aae80f00a18c8b1f4f4',
    downloadUrl: `${ENDPOINT}/storage/buckets/progress-photos/files/6aae80f00a18c8b1f4f4/view?project=${PROJECT_ID}`,
    dayNumber: 4,
    createdAt: '2026-09-19T18:02:48.033',
    pose: 'Front',
    weightAtCapture: null,
    notes: '[Day 4]',
    workoutId: null,
  },
  {
    id: 'photo-1789821170117',
    storagePath: '6aae80f223c22baf95b6',
    downloadUrl: `${ENDPOINT}/storage/buckets/progress-photos/files/6aae80f223c22baf95b6/view?project=${PROJECT_ID}`,
    dayNumber: 5,
    createdAt: '2026-09-19T18:02:50.117',
    pose: 'Front',
    weightAtCapture: null,
    notes: '[Day 5]',
    workoutId: null,
  },
  {
    id: 'photo-1789821171365',
    storagePath: '6aae80f361c723afd7e6',
    downloadUrl: `${ENDPOINT}/storage/buckets/progress-photos/files/6aae80f361c723afd7e6/view?project=${PROJECT_ID}`,
    dayNumber: 6,
    createdAt: '2026-09-19T18:02:51.365',
    pose: 'Front',
    weightAtCapture: null,
    notes: '[Day 6]',
    workoutId: null,
  },
  {
    id: 'photo-1789821172718',
    storagePath: '6aae80f4b6bfb988831b',
    downloadUrl: `${ENDPOINT}/storage/buckets/progress-photos/files/6aae80f4b6bfb988831b/view?project=${PROJECT_ID}`,
    dayNumber: 7,
    createdAt: '2026-09-19T18:02:52.718',
    pose: 'Front',
    weightAtCapture: null,
    notes: '[Day 7]',
    workoutId: null,
  },
];

async function run() {
  const jsonStr = JSON.stringify(manifest);
  const res = await fetch(`${ENDPOINT}/users/${USER_ID}/prefs`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': PROJECT_ID,
      'X-Appwrite-Key': API_KEY,
    },
    body: JSON.stringify({
      prefs: {
        [`photos_manifest_${USER_ID}`]: jsonStr,
        photos_manifest: jsonStr,
      },
    }),
  });

  const data = await res.json();
  console.log('Update result status:', res.status);
  console.log('Updated user preferences successfully!');
}

run().catch(console.error);
