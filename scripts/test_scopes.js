const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '6aac02f1002c53d0bc56';
const API_KEY = process.argv[2];

async function test(name, url, method = 'GET', body = null) {
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': PROJECT_ID,
      'X-Appwrite-Key': API_KEY,
    },
  };
  if (body) options.body = JSON.stringify(body);

  const res = await fetch(`${ENDPOINT}${url}`, options);
  const text = await res.text();
  console.log(`[${res.status}] ${name} -> ${text.slice(0, 120)}`);
}

async function main() {
  console.log('Testing scopes for key:', API_KEY.slice(0, 20) + '...');
  await test('Users', '/users');
  await test('Databases', '/databases');
  await test('Buckets', '/storage/buckets');
  await test('List Collections', '/databases/fittrack/collections');
  await test('Create Collection Test', '/databases/fittrack/collections', 'POST', {
    collectionId: 'test_col',
    name: 'Test',
    permissions: [],
  });
}

main().catch(console.error);
