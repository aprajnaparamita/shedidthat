
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import Anthropic from '@anthropic-ai/sdk';

const app = new Hono();

// --- Middleware ---

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
      console.log(`[Speech] Found audio for UUID: ${uuid}. Deleting from cache and streaming.`);
      await env.SPEECH_CACHE.delete(uuid);
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
    console.error('Registration error:', error);
    return c.json({ error: 'Failed to register device' }, 500);
  }
});

app.get('/api/speech/:uuid', async (c) => {
    const { uuid } = c.req.param();
    return handleSpeechRequest(uuid, c.env);
});

class Stream {
  constructor(c) {
    const { readable, writable } = new TransformStream();
    this.writer = writable.getWriter();
    this.encoder = new TextEncoder();
    this.response = c.body(readable, {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
      },
    });
  }

  async write(data) {
    const eventData = JSON.stringify(data);
    await this.writer.write(this.encoder.encode(`data: ${eventData}\n\n`));
  }

  async close() {
    await this.writer.close();
  }
}

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
    const systemMessage = c.env[`PERSONA_${lang.toUpperCase()}`] || c.env.PERSONA_EN;
    console.log(`[CHAT] Using ${lang.toUpperCase()} persona.`);

    const aiStream = await anthropic.messages.stream({
      model: "claude-3-haiku-20240307",
      max_tokens: 1024,
      messages: messageHistory,
      system: systemMessage,
    });

    const stream = new Stream(c);
    let fullMessage = "";

    (async () => {
      try {
        for await (const chunk of aiStream) {
          if (chunk.type === 'content_block_delta') {
            const text = chunk.delta.text;
            fullMessage += text;
            await stream.write({ content: text });
          }
        }
        
        const speechUUID = crypto.randomUUID();
        const speechUrl = `/api/speech/${speechUUID}`;
        await stream.write({ done: true, speechUrl: speechUrl });

        c.executionCtx.waitUntil(handleTTS(fullMessage, speechUUID, lang, c.env));

      } catch (e) {
        console.error("[CHAT] Streaming error:", e);
      } finally {
        console.log("[CHAT] Finished streaming from AI.");
        await stream.close();
      }
    })();

    return stream.response;

  } catch (error) {
    console.error('Chat error:', error);
    return c.json({ error: 'An error occurred during the chat.' }, 500);
  }
});

export default app;
