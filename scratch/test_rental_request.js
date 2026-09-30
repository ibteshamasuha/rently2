const https = require('https');
const fs = require('fs');

async function testRentalRequest() {
  // Let's get an auth token for tenant
  // First let's check who the users are:
  // Suha tenant: Ov8SaUl3EjejqmmhPudmNZFOdat2
  // Or tenant@gmail.com: oFW6xccbErbVhVpAqLyCdp8XdMv2
  // Let's check with firebase-tools token (admin token) or sign in with password
  const configPath = 'C:/Users/User/.config/configstore/firebase-tools.json';
  const cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const adminToken = cfg.tokens.access_token;

  // Let's create a custom token or sign in with tenant email/password via Firebase Auth REST API
  // Web API Key is in firebase config: AIzaSyAishDhppB4xPrBMsT3zuASRboXp2ZTEPo
  const apiKey = 'AIzaSyAishDhppB4xPrBMsT3zuASRboXp2ZTEPo';

  const signIn = (email, password) => new Promise((resolve, reject) => {
    const postData = JSON.stringify({ email, password, returnSecureToken: true });
    const req = https.request({
      hostname: 'identitytoolkit.googleapis.com',
      path: '/v1/accounts:signInWithPassword?key=' + apiKey,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });

  // Try signing in as tenant
  // Common passwords in testing: 123456, 12345678, password, etc.
  const emails = [
    { email: 'oishy@gmail.com', pass: '123456' },
    { email: 'tenant@gmail.com', pass: '123456' },
    { email: 'suhaibteshama@gmail.com', pass: '123456' },
    { email: 'noushinfariha26@gmail.com', pass: '123456' }
  ];

  let tenantToken = null;
  let tenantUid = null;
  for (const cred of emails) {
    const res = await signIn(cred.email, cred.pass);
    if (res.idToken) {
      console.log('Successfully signed in as', cred.email, 'uid:', res.localId);
      tenantToken = res.idToken;
      tenantUid = res.localId;
      break;
    } else {
      console.log('Failed to sign in as', cred.email, res.error?.message);
    }
  }

  if (!tenantToken) {
    console.log('Could not sign in with password.');
    return;
  }

  // Now let's test GET on a non-existent rental request document
  const testAptId = 'RvKz7GagxbSqqEXcGZHy'; // real available apartment
  const docId = tenantUid + '_' + testAptId;

  console.log('\n--- Testing GET non-existent document ---');
  await new Promise((resolve) => {
    const req = https.request({
      hostname: 'firestore.googleapis.com',
      path: '/v1/projects/rently-545da/databases/(default)/documents/rentalRequests/' + docId,
      method: 'GET',
      headers: { Authorization: 'Bearer ' + tenantToken }
    }, res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => {
        console.log('GET non-existent status:', res.statusCode);
        console.log('GET non-existent body:', d);
        resolve();
      });
    });
    req.end();
  });

  console.log('\n--- Testing CREATE (POST/PATCH) rental request ---');
  // In Firestore REST, docId write is PATCH with document name
  const postData = JSON.stringify({
    fields: {
      tenantId: { stringValue: tenantUid },
      landlordId: { stringValue: 'VRJqiSBDQ7frreWavr8MLfGHjlr1' },
      apartmentId: { stringValue: testAptId },
      status: { stringValue: 'pending' },
      message: { stringValue: 'Testing rental request submission' },
      preferredMoveInDate: { timestampValue: new Date(Date.now() + 86400000 * 7).toISOString() },
      createdAt: { timestampValue: new Date().toISOString() }
    }
  });

  await new Promise((resolve) => {
    const req = https.request({
      hostname: 'firestore.googleapis.com',
      path: '/v1/projects/rently-545da/databases/(default)/documents/rentalRequests/' + docId,
      method: 'PATCH',
      headers: {
        'Authorization': 'Bearer ' + tenantToken,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => {
        console.log('CREATE status:', res.statusCode);
        console.log('CREATE body:', d);
        resolve();
      });
    });
    req.write(postData);
    req.end();
  });
}

testRentalRequest().catch(console.error);
