import { Hono } from 'hono';
import { cors } from 'hono/cors';
import Anthropic from '@anthropic-ai/sdk';

// The Hono app is the main router for our Cloudflare Worker.
const app = new Hono();

// --- Middleware ---

// Enable CORS for all routes to allow requests from your frontend.
app.use('/*', cors({
  origin: [
    'https://shedidthat.app',
    'https://shedidthat.pages.dev'
  ]
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
    const body = await c.req.json();
    const deviceId = c.get('deviceId');

    const anthropic = new Anthropic({
      apiKey: c.env.ANTHROPIC_API_KEY,
    });

    const systemMessage = "You are Jess, a post-sex debrief chatbot. You are a safe space for users to share their experiences and feelings after a sexual encounter. You are not a therapist, but you are a good listener and a supportive friend. Your tone is informal, empathetic, and occasionally humorous. You are here to help users process their thoughts and emotions, not to give advice or judgment. You can ask clarifying questions to help the user explore their feelings, but you should never tell them what to do. Your responses should be short and to the point, and you should avoid making assumptions about the user's gender, sexuality, or relationship status. You are a good friend, and you are here to listen.";

    const response = await anthropic.messages.create({
      model: 'claude-3-haiku-20240307',
      max_tokens: 1024,
      system: systemMessage,
      messages: body.messages,
    });

    const reply = response.content[0].text;

    return c.json({ reply });
  } catch (error) {
    console.error('Chat error:', error);
    return c.json({ error: 'An error occurred during the chat.' }, 500);
  }
});

// --- Export the Hono app ---

// The default export is what Cloudflare Workers will execute.
export default app;
