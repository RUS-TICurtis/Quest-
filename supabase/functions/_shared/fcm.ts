import { SignJWT, importPKCS8 } from 'https://deno.land/x/jose@v4.14.4/index.ts';

// In-memory cache for the FCM access token
let cachedToken: string | null = null;
let tokenExpirationTime: number = 0;

// Get OAuth2 Access Token for FCM HTTP v1 using raw Private Key
export async function getFcmAccessToken(): Promise<{ accessToken: string, projectId: string }> {
  const fcmSecret = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_B64');
  if (!fcmSecret) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_B64 secret is missing in Supabase.');
  }

  const serviceAccount = JSON.parse(atob(fcmSecret));
  const projectId = serviceAccount.project_id;

  // Use cached token if valid (buffer of 5 minutes)
  const now = Date.now();
  if (cachedToken && tokenExpirationTime > now + 5 * 60 * 1000) {
    return { accessToken: cachedToken, projectId };
  }
  
  // 1. Force fix broken newline escape sequences
  let pKey = serviceAccount.private_key;
  
  if (!pKey) {
    throw new Error(`Google Service Account JSON is missing 'private_key'. Found keys: ${Object.keys(serviceAccount).join(', ')}`);
  }

  if (!pKey.includes('-----BEGIN PRIVATE KEY-----')) {
    throw new Error('Invalid Google Service Account format or missing PKCS8 key block.');
  }

  // Sometimes JSON.parse or base64 injection double escapes newlines mapping \n to \\n
  pKey = pKey.replace(/\\n/g, '\n');

  const privateKey = await importPKCS8(pKey, 'RS256');

  const jwt = await new SignJWT({
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(privateKey);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Failed to get FCM OAuth2 token: ${errText}`);
  }

  const data = await response.json();

  // Cache the new token
  cachedToken = data.access_token;
  // data.expires_in is usually 3600 seconds (1 hour)
  const expiresInMs = (data.expires_in || 3600) * 1000;
  tokenExpirationTime = now + expiresInMs;

  return { accessToken: cachedToken as string, projectId };
}

export async function sendFCMMessage(
  payload: any, 
  accessToken: string, 
  projectId: string
): Promise<boolean> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    }
  );
  
  if (!response.ok) {
     console.error(`FCM Send Error: [${response.status}]`, await response.text());
     return false;
  }
  return true;
}

export async function sendToTopic(
  payload: any,
  accessToken: string,
  projectId: string
): Promise<boolean> {
  // FCM HTTP v1 API is the same for tokens and topics, it's just the payload that differs
  return sendFCMMessage(payload, accessToken, projectId);
}
