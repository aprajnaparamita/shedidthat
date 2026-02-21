import { Hono } from 'hono';
import { cors } from 'hono/cors';
import Anthropic from '@anthropic-ai/sdk';

// The Hono app is the main router for our Cloudflare Worker.
const app = new Hono();

// --- Middleware ---

// Enable CORS for all routes to allow requests from your frontend.
app.use('/*', cors({
  origin: '*',
  allowHeaders: ['Content-Type', 'X-App-Secret', 'X-Device-Id'],
  allowMethods: ['POST', 'GET', 'OPTIONS'],
}));

// Authentication Middleware: Checks for a valid secret and registered device.
const authMiddleware = async (c, next) => {
  const secret = c.req.header('X-App-Secret');
  const deviceId = c.req.header('X-Device-Id');

  // c.env contains environment variables and bindings set in wrangler.toml or the dashboard.
  if (secret !== c.env.APP_SECRET) {
    return c.json({ error: 'Nope.' }, 401);
  }

  if (!deviceId) {
    return c.json({ error: 'Device ID is required.' }, 400);
  }

  // Check if the device is registered in our Cloudflare KV store.
  // c.env.DEVICE_KV is the binding to our KV namespace.
  const isRegistered = await c.env.DEVICE_KV.get(deviceId);
  if (!isRegistered) {
    return c.json({ error: 'Device not registered.' }, 401);
  }

  // Add deviceId to the context to use in later handlers.
  c.set('deviceId', deviceId);
  await next();
};

// Rate Limiting Middleware: Limits requests per device.
const rateLimitMiddleware = async (c, next) => {
  const deviceId = c.get('deviceId');
  const now = Date.now();
  const windowMs = 15 * 60 * 1000; // 15 minutes
  const maxRequests = 100;

  const key = `rate-limit:${deviceId}`;
  const storedData = await c.env.DEVICE_KV.get(key, { type: 'json' });

  if (storedData && (now - storedData.timestamp) < windowMs) {
    if (storedData.count >= maxRequests) {
      return c.json({ error: 'Too many requests, please try again later.' }, 429);
    }
    // Update the count and timestamp, expiring after the window.
    await c.env.DEVICE_KV.put(key, JSON.stringify({ count: storedData.count + 1, timestamp: storedData.timestamp }), { expirationTtl: windowMs / 1000 });
  } else {
    // Start a new window for the user.
    await c.env.DEVICE_KV.put(key, JSON.stringify({ count: 1, timestamp: now }), { expirationTtl: windowMs / 1000 });
  }

  await next();
};

// --- Routes ---

// Health check route
app.get('/', (c) => c.text('She Absolutely Just Did That - Backend is running!'));

// POST /register: Registers a new device.
app.post('/register', async (c) => {
  try {
    const { deviceId } = await c.req.json();
    if (!deviceId) {
      return c.json({ error: 'Device ID is required for registration.' }, 400);
    }

    // Store the deviceId in the KV store. The value can be simple, we just need the key to exist.
    // We set an expiration TTL (Time To Live) of 1 year (in seconds).
    const oneYearInSeconds = 365 * 24 * 60 * 60;
    await c.env.DEVICE_KV.put(deviceId, 'registered', { expirationTtl: oneYearInSeconds });

    console.log(`Device registered: ${deviceId}`);
    return c.json({ message: 'Device registered successfully' });
  } catch (error) {
    console.error('Registration error:', error);
    return c.json({ error: 'Failed to register device' }, 500);
  }
});

// POST /chat: Handles chat messages, protected by auth and rate limiting.
app.post('/chat', authMiddleware, rateLimitMiddleware, async (c) => {
  try {
    const deviceId = c.get('deviceId');
    const lang = c.req.query('lang') || 'en';
    console.error(`[CHAT] Received request for device: ${deviceId}, lang: ${lang}`);

    const { messages: messageHistory } = await c.req.json();
    console.error(`[CHAT] Received ${messageHistory.length} messages in history.`);

    if (!messageHistory || messageHistory.length === 0) {
      return c.json({ error: "Messages are required." }, 400);
    }

    const anthropic = new Anthropic({
      apiKey: c.env.ANTHROPIC_API_KEY,
    });

    let systemMessage;
    switch (lang) {
      case 'zh':
        systemMessage = c.env.PERSONA_ZH;
        console.error("[CHAT] Using Chinese persona.");
        break;
      case 'th':
        systemMessage = c.env.PERSONA_TH;
        console.error("[CHAT] Using Thai persona.");
        break;
      case 'en':
      default:
        systemMessage = c.env.PERSONA_EN;
        console.error("[CHAT] Using English persona.");
        break;
    }



    try {
      console.error("[CHAT] Sending request to Anthropic API...");
      const stream = await anthropic.messages.stream({
        model: "claude-3-haiku-20240307",
        max_tokens: 1024,
        messages: messageHistory,
        system: systemMessage,
      });

      const { readable, writable } = new TransformStream();
      const writer = writable.getWriter();

      // Asynchronously process the stream from Anthropic and pipe it to the client.
      (async () => {
        try {
          for await (const chunk of stream) {
            if (chunk.type === 'content_block_delta') {
              const text = chunk.delta.text;
              console.error(`[CHAT] AI chunk received: "${text}"`);
              await writer.write(new TextEncoder().encode(text));
            }
          }
        } catch (e) {
          console.error("[CHAT] Streaming error:", e);
          // Close the writer on error to prevent the client from hanging.
          await writer.close();
        } finally {
          console.log("[CHAT] Finished streaming from AI.");
          await writer.close();
        }
      })();

      return c.body(readable, {
        headers: {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          "Connection": "keep-alive",
        },
      });
    } catch (error) {
      console.error("[CHAT] Error calling Anthropic API:", error);
      return c.json({ error: "Failed to get response from AI." }, 500);
    }
  } catch (error) {
    console.error('Chat error:', error);
    return c.json({ error: 'An error occurred during the chat.' }, 500);
  }
});

// --- Export the Hono app ---

// The default export is what Cloudflare Workers will execute.
export default app;
