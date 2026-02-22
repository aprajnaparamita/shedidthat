const fetch = require('node-fetch');
const { randomUUID } = require('crypto');

const PROD_URL = process.env.PROD_URL;
const APP_SECRET = process.env.APP_SECRET;

if (!PROD_URL || !APP_SECRET) {
  console.error('Error: Please set the PROD_URL and APP_SECRET environment variables.');
  console.error('Example: PROD_URL=https://api.shedidthat.app APP_SECRET=your_secret_here node tools/test_sentry.js');
  process.exit(1);
}

async function runTest() {
  const deviceId = randomUUID();
  console.log(`[1/3] Using new device ID: ${deviceId}`);

  try {
    // Step 2: Register the new device
    console.log(`[2/3] Registering device with production server at ${PROD_URL}...`);
    const registerResponse = await fetch(`${PROD_URL}/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ deviceId }),
    });


    if (registerResponse.status !== 200) {
      const body = await registerResponse.text();
      throw new Error(`Failed to register device. Status: ${registerResponse.status}, Body: ${body}`);
    }
    console.log('Device registered successfully.');

    // Step 3: Trigger the Sentry test endpoint
    console.log('[3/3] Triggering Sentry test endpoint...');
    const sentryResponse = await fetch(`${PROD_URL}/sentrytest`, {
      headers: {
        'x-device-id': deviceId,
        'x-app-secret': APP_SECRET,
      },
    });
    console.log('Sentry response status:', sentryResponse.status);
    const body = await sentryResponse.text();
    console.log('Sentry response body:', body);

    // We expect a 500 error here
    if (sentryResponse.status === 500) {
      console.log('Successfully triggered Sentry test endpoint. Received expected 500 error.');
      console.log('Check your Sentry dashboard for the new issue!');
    } else {
      const body = await sentryResponse.text();
      throw new Error(`Expected a 500 error but got ${sentryResponse.status}. Body: ${body}`);
    }

  } catch (error) {
    console.error('Sentry test script failed:', error.message);
    process.exit(1);
  }
}

runTest();
