const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '6aac02f1002c53d0bc56';
const KEY_ID = '6aae9988003bcba1e24b';
const API_KEY = 'standard_3d09749667cd573925c933e75303190342c854f9fa81065f38c2678fbecc292c6d82d201f55dbd53f3644696830dfadce6ee0cc7170c0e8819993987846ee9d9efec1573e51fda12a11c623930baca6ed77b246c629a1a74ef9c33cb43984ee899085bb2834e372a440bacf7b36000157de7cf4b831816471efde75c25cecab6';

async function updateKeyScopes() {
  const getRes = await fetch(`${ENDPOINT}/projects/${PROJECT_ID}/keys/${KEY_ID}`, {
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': PROJECT_ID,
      'X-Appwrite-Key': API_KEY,
    },
  });
  const currentKey = await getRes.json();
  const currentScopes = new Set(currentKey.scopes || []);

  const neededScopes = [
    'collections.read',
    'collections.write',
    'attributes.read',
    'attributes.write',
    'indexes.read',
    'indexes.write',
    'documents.read',
    'documents.write',
    'databases.read',
    'databases.write',
    'documentsdb.collections.read',
    'documentsdb.collections.write',
    'documentsdb.documents.read',
    'documentsdb.documents.write',
    'documentsdb.indexes.read',
    'documentsdb.indexes.write',
    'documentsdb.read',
    'documentsdb.write',
    'tables.read',
    'tables.write',
    'columns.read',
    'columns.write',
    'rows.read',
    'rows.write',
  ];

  for (const s of neededScopes) {
    currentScopes.add(s);
  }

  const patchRes = await fetch(`${ENDPOINT}/projects/${PROJECT_ID}/keys/${KEY_ID}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': PROJECT_ID,
      'X-Appwrite-Key': API_KEY,
    },
    body: JSON.stringify({
      name: currentKey.name,
      scopes: Array.from(currentScopes),
      expire: currentKey.expire || null,
    }),
  });

  const updated = await patchRes.json();
  console.log('Update key scopes status:', patchRes.status);
  console.log('Has collections.write:', updated.scopes ? updated.scopes.includes('collections.write') : 'error', updated.message || '');
}

updateKeyScopes().catch(console.error);
