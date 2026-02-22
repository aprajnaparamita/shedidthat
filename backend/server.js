
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import Anthropic from '@anthropic-ai/sdk';
import { Toucan } from 'toucan-js';


import personaEN from './persona.en.md';
import personaZH from './persona.zh.md';
import personaTH from './persona.th.md';

const PERSONAS = {
  EN: personaEN,
  ZH: personaZH,
  TH: personaTH,
};

const app = new Hono();

app.use(async (c, next) => {
  const sentry = new Toucan({
    dsn: c.env.SENTRY_DSN,
    context: c.executionCtx,
    request: c.req.raw,
  });
  c.set('sentry', sentry);
  await next();
});

// --- Middleware ---

app.onError((err, c) => {
  try {
    if (c.env.SENTRY_DSN) {
      console.log('SENTRY_DSN is present, initializing Sentry to report error.');
      const sentry = new Toucan({
        dsn: c.env.SENTRY_DSN,
        context: c.executionCtx,
        request: c.req.raw,
      });
      // Explicitly use waitUntil to ensure the async request to Sentry completes
      c.executionCtx.waitUntil(
        (async () => {
          sentry.captureException(err);
          console.log('Sentry captureException has been called.');
        })()
      );
    } else {
      console.error('SENTRY_DSN secret not found. Cannot report error to Sentry.');
    }
  } catch (e) {
    // If Sentry initialization itself fails, log that error.
    console.error('Failed to initialize or use Sentry:', e);
  }

  return c.text('Internal Server Error', 500);
});

app.use('/*', cors({
  origin: '*',
  allowHeaders: ['Content-Type', 'x-app-secret', 'x-device-id'],
  allowMethods: ['POST', 'GET', 'OPTIONS'],
}));

const authMiddleware = async (c, next) => {
  const secret = c.req.header('x-app-secret');
  const deviceId = c.req.header('x-device-id');

  if (secret !== c.env.APP_SECRET) {
    return c.json({ error: 'Nope.' }, 401);
  }

  if (!deviceId) {
    return c.json({ error: 'Device ID is required.' }, 400);
  }

  const isRegistered = await c.env.DEVICE_KV.get(deviceId);
  if (!isRegistered) {
    return c.json({ error: 'Device not registered.' }, 401);
  }

  c.set('deviceId', deviceId);
  await next();
};

const rateLimitMiddleware = async (c, next) => {
  const deviceId = c.get('deviceId');
  const now = Date.now();
  const windowMs = 15 * 60 * 1000;
  const maxRequests = 100;

  const key = `rate-limit:${deviceId}`;
  const storedData = await c.env.DEVICE_KV.get(key, { type: 'json' });

  if (storedData && (now - storedData.timestamp) < windowMs) {
    if (storedData.count >= maxRequests) {
      return c.json({ error: 'Too many requests, please try again later.' }, 429);
    }
    await c.env.DEVICE_KV.put(key, JSON.stringify({ count: storedData.count + 1, timestamp: storedData.timestamp }), { expirationTtl: windowMs / 1000 });
  } else {
    await c.env.DEVICE_KV.put(key, JSON.stringify({ count: 1, timestamp: now }), { expirationTtl: windowMs / 1000 });
  }

  await next();
};

// --- TTS Handling ---

const VOICES = {
  en: { languageCode: 'en-US', name: 'en-US-Journey-F' },
  th: { languageCode: 'th-TH', name: 'th-TH-Neural2-C' },
  zh: { languageCode: 'cmn-CN', name: 'cmn-CN-Wavenet-D' }
};

async function handleTTS(text, uuid, lang, env) {
  try {
    console.log(`[TTS] Generating speech for UUID: ${uuid}`);
    const voice = VOICES[lang] || VOICES.en;
    const response = await fetch(
      `https://texttospeech.googleapis.com/v1/text:synthesize?key=${env.GOOGLE_TEXT_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          input: { text },
          voice: voice,
          audioConfig: { audioEncoding: 'MP3', speakingRate: 1.1 }
        })
      }
    );

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`Google TTS API failed with status ${response.status}: ${errorBody}`);
    }

    const data = await response.json();
    if (data.audioContent) {
      await env.SPEECH_CACHE.put(uuid, data.audioContent, { expirationTtl: 60 });
      console.log(`[TTS] Stored audio in SPEECH_CACHE for UUID: ${uuid}`);
    } else {
      console.error('[TTS] Google TTS response did not contain audioContent.');
    }
  } catch (error) {
    console.error(`[TTS] Error in handleTTS for UUID ${uuid}:`, error);
  }
}

async function handleSpeechRequest(uuid, env) {
  const maxWait = 10000;
  const interval = 200;
  let elapsed = 0;

  while (elapsed < maxWait) {
    const audio = await env.SPEECH_CACHE.get(uuid);
    if (audio) {
      console.log(`[Speech] Found audio for UUID: ${uuid}. Streaming from cache.`);
      const binary = Uint8Array.from(atob(audio), c => c.charCodeAt(0));
      return new Response(binary, {
        headers: {
          'Content-Type': 'audio/mpeg',
          'Content-Length': binary.length.toString(),
          'Cache-Control': 'no-store'
        }
      });
    }
    await new Promise(resolve => setTimeout(resolve, interval));
    elapsed += interval;
  }

  console.log(`[Speech] Timed out waiting for audio for UUID: ${uuid}`);
  return new Response(null, { status: 404 });
}


// --- Routes ---

app.get('/', (c) => c.text('She Absolutely Just Did That - Backend is running!'));

app.post('/register', async (c) => {
  try {
    const { deviceId } = await c.req.json();
    if (!deviceId) {
      return c.json({ error: 'Device ID is required for registration.' }, 400);
    }
    const oneYearInSeconds = 365 * 24 * 60 * 60;
    await c.env.DEVICE_KV.put(deviceId, 'registered', { expirationTtl: oneYearInSeconds });
    console.log(`Device registered: ${deviceId}`);
    return c.json({ message: 'Device registered successfully' });
  } catch (error) {
    c.get('sentry').captureException(error);
    console.error('Registration error:', error);
    return c.json({ error: 'Failed to register device' }, 500);
  }
});

app.get('/api/speech/:uuid', async (c) => {
    const { uuid } = c.req.param();
    return handleSpeechRequest(uuid, c.env);
});

app.get('/sentrytest', authMiddleware, async (c) => {
  throw new Error('This is a Sentry test exception from the backend.');
});

app.post('/chat', authMiddleware, rateLimitMiddleware, async (c) => {
  try {
    const deviceId = c.get('deviceId');
    const lang = c.req.query('lang') || 'en';
    console.log(`[CHAT] Received request for device: ${deviceId}, lang: ${lang}`);

    const { messages: messageHistory } = await c.req.json();
    console.log(`[CHAT] Received ${messageHistory.length} messages in history.`);

    if (!messageHistory || messageHistory.length === 0) {
      return c.json({ error: "Messages are required." }, 400);
    }

    const anthropic = new Anthropic({ apiKey: c.env.ANTHROPIC_API_KEY });
    const systemMessage = PERSONAS[lang.toUpperCase()] || PERSONAS.EN;
    console.log(`[CHAT] Using ${lang.toUpperCase()} persona.`);

    // 1. Get the full response from the AI first.
    const msg = await anthropic.messages.create({
      model: "claude-3-haiku-20240307",
      max_tokens: 1024,
      messages: messageHistory,
      system: systemMessage,
    });

    const fullMessage = msg.content[0].text;
    console.log(`[CHAT] Full message received from AI: ${fullMessage}`);

    // 2. Prepare for streaming the response.
    const { readable, writable } = new TransformStream();
    const writer = writable.getWriter();
    const encoder = new TextEncoder();

    // 3. Start a non-blocking process to stream the chunks.
    (async () => {
      // 3a. Split the message into word-like chunks for a typing effect.
      const chunks = fullMessage.match(/\S+\s*/g) || [fullMessage];

      for (const chunk of chunks) {
        await writer.write(encoder.encode(`data: ${JSON.stringify({ content: chunk })}\n\n`));
        // Add a small delay to simulate typing
        await new Promise(resolve => setTimeout(resolve, 50)); 
      }

      // 3b. Send the final message with the speech URL.
      const speechUUID = crypto.randomUUID();
      const speechUrl = `/api/speech/${speechUUID}`;
      await writer.write(encoder.encode(`data: ${JSON.stringify({ done: true, speechUrl: speechUrl })}\n\n`));
      
      // 3c. Start the TTS generation in the background.
      c.executionCtx.waitUntil(handleTTS(fullMessage, speechUUID, lang, c.env));

      // 3d. Close the stream.
      await writer.close();
    })();

    // 4. Return the readable stream to the client immediately.
    return c.body(readable, {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
      },
    });

  } catch (error) {
    c.get('sentry').captureException(error);
    console.error('Chat error:', error);
    return c.json({ error: 'An error occurred during the chat.' }, 500);
  }
});

export default app;
