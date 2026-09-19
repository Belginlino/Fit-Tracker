const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '6aac02f1002c53d0bc56';
const DATABASE_ID = 'fittrack';
const USER_ID = '6aac069ce6f50648c106';
const API_KEY = process.argv[2];

const photos = [
  {
    id: 'photo-1789755644834',
    userId: USER_ID,
    fileId: '6aad80fccd9a852e7659',
    storagePath: '6aad80fccd9a852e7659',
    pose: 'Front',
    workoutId: '',
    weightAtCapture: 74.0,
    notes: '[Day 1]',
    dayNumber: 1,
    createdAt: '2026-09-18T23:50:44.834',
  },
  {
    id: 'photo-1789820869738',
    userId: USER_ID,
    fileId: '6aae7fc5b65044c9fdea',
    storagePath: '6aae7fc5b65044c9fdea',
    pose: 'Front',
    workoutId: '',
    weightAtCapture: 74.0,
    notes: '[Day 2]',
    dayNumber: 2,
    createdAt: '2026-09-19T17:57:49.738',
  },
  {
    id: 'photo-1789821022893',
    userId: USER_ID,
    fileId: '6aae805edc3b25dc957e',
    storagePath: '6aae805edc3b25dc957e',
    pose: 'Front',
    workoutId: '',
    weightAtCapture: 74.0,
    notes: '[Day 3]',
    dayNumber: 3,
    createdAt: '2026-09-19T18:00:22.893',
  },
  {
    id: 'photo-1789821168033',
    userId: USER_ID,
    fileId: '6aae80f00a18c8b1f4f4',
    storagePath: '6aae80f00a18c8b1f4f4',
    pose: 'Front',
    workoutId: '',
    weightAtCapture: 74.0,
    notes: '[Day 4]',
    dayNumber: 4,
    createdAt: '2026-09-19T18:02:48.033',
  },
  {
    id: 'photo-1789821170117',
    userId: USER_ID,
    fileId: '6aae80f223c22baf95b6',
    storagePath: '6aae80f223c22baf95b6',
    pose: 'Front',
    workoutId: '',
    weightAtCapture: 74.0,
    notes: '[Day 5]',
    dayNumber: 5,
    createdAt: '2026-09-19T18:02:50.117',
  },
  {
    id: 'photo-1789821171365',
    userId: USER_ID,
    fileId: '6aae80f361c723afd7e6',
    storagePath: '6aae80f361c723afd7e6',
    pose: 'Front',
    workoutId: '',
    weightAtCapture: 74.0,
    notes: '[Day 6]',
    dayNumber: 6,
    createdAt: '2026-09-19T18:02:51.365',
  },
  {
    id: 'photo-1789821172718',
    userId: USER_ID,
    fileId: '6aae80f4b6bfb988831b',
    storagePath: '6aae80f4b6bfb988831b',
    pose: 'Front',
    workoutId: '',
    weightAtCapture: 74.0,
    notes: '[Day 7]',
    dayNumber: 7,
    createdAt: '2026-09-19T18:02:52.718',
  },
];

async function sync() {
  console.log('Inserting 7 progress photo documents into Appwrite database collection...');
  for (const p of photos) {
    const docData = {
      user_id: p.userId,
      file_id: p.fileId,
      storage_path: p.storagePath,
      pose: p.pose,
      workout_id: p.workoutId,
      weight_at_capture: p.weightAtCapture,
      notes: p.notes,
      day_number: p.dayNumber,
      created_at: p.createdAt,
    };

    const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/progress_photos/documents`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': PROJECT_ID,
        'X-Appwrite-Key': API_KEY,
      },
      body: JSON.stringify({
        documentId: p.id,
        data: docData,
        permissions: ['read("any")', 'write("any")', 'update("any")', 'delete("any")'],
      }),
    });

    const text = await res.text();
    console.log(`Document ${p.id} (${p.notes}):`, res.status, res.ok ? 'Created ✓' : text.slice(0, 80));
  }
}

sync().catch(console.error);
