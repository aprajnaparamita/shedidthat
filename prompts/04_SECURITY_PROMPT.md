# Prompt 4 — Security Hardening

Paste this entire prompt into your local Claude instance to add or audit security on the backend.

---

I have an Express.js backend for a chatbot app called "She Absolutely Just Did That." Here is the current server.js:


const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { Anthropic } = require('@anthropic-ai/sdk');

if (process.env.NODE_ENV === 'test') {
  require('dotenv').config({ path: '.env.test' });
} else {
  require('dotenv').config();
}
const fs = require('fs');
const path = require('path');

const app = express();
const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
const registeredDevices = new Set();
const usageTracker = new Map();

// Load persona once at startup
const SYSTEM_PROMPT = fs.readFileSync(path.join(__dirname, 'persona.md'), 'utf8');

// Middleware
app.use(cors());
app.use(express.json());

// App secret middleware
const appSecretMiddleware = (req, res, next) => {
  const appSecret = req.get('x-app-secret');
  if (appSecret !== process.env.APP_SECRET) {
    return res.status(401).json({ error: 'Nope.' });
  }
  next();
};
app.use('/chat', appSecretMiddleware);

// Device token middleware
const deviceTokenMiddleware = (req, res, next) => {
  const deviceToken = req.get('x-device-token');
  if (!registeredDevices.has(deviceToken)) {
    return res.status(401).json({ error: 'Nope.' });
  }
  next();
};
app.use('/chat', deviceTokenMiddleware);

// Rate limiting
const burstLimiter = rateLimit({
  windowMs: 10 * 1000, // 10 seconds
  max: 5,
  message: { error: 'Slow down babe.' }
});
app.use('/chat', burstLimiter);

const dailyLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000, // 24 hours
  max: 50,
  message: { error: 'Easy there! Come back tomorrow with more stories.' }
});
app.use('/chat', dailyLimiter);

// Health check
app.get('/health', (req, res) => res.json({ status: 'Jess is ready and waiting' }));

// Register device
app.post('/register', (req, res) => {
  const { deviceToken } = req.body;
  if (!deviceToken) {
    return res.status(400).json({ error: 'deviceToken required' });
  }
  registeredDevices.add(deviceToken);
  res.status(200).json({ status: 'Device registered' });
});

// Main chat endpoint
app.post('/chat', async (req, res) => {
  const deviceToken = req.get('x-device-token');
  const currentUsage = usageTracker.get(deviceToken) || 0;

  if (currentUsage >= 100) {
    return res.status(429).json({ error: "You've had quite the day. Come back tomorrow." });
  }

  const { messages } = req.body;

  if (!messages || !Array.isArray(messages)) {
    return res.status(400).json({ error: 'messages array required' });
  }

  if (messages.length > 30) {
    return res.status(400).json({ error: 'That is a LOT of debrief.' });
  }

  // Validate message format
  const validMessages = messages.every(m =>
    m.role && ['user', 'assistant'].includes(m.role) && typeof m.content === 'string' && m.content.length <= 500
  );
  if (!validMessages) {
    return res.status(400).json({ error: 'Summarise babe, I have questions.' });
  }

  try {
    const response = await client.messages.create({
      model: 'claude-haiku-4-5-20251001', // Cheapest!
      max_tokens: 300,                     // Keep Jess snappy, not wordy
      system: SYSTEM_PROMPT,
      messages: messages
    });

    res.json({ reply: response.content[0].text });

    const newUsage = currentUsage + 1;
    usageTracker.set(deviceToken, newUsage);
    if (newUsage > 20) {
      console.warn(`Device ${deviceToken} has sent ${newUsage} messages.`);
    }
  } catch (error) {
    console.error('Anthropic error:', error);
    res.status(500).json({ error: 'Jess is having a moment, try again' });
  }
});

const PORT = process.env.PORT || 8080;
const server = app.listen(PORT, () => console.log(`Jess is live on port ${PORT}`));

module.exports = { app, server, registeredDevices };

Please audit this backend for security vulnerabilities and improve it. Specifically check for and fix all of the following:

1. RATE LIMITING
   - Burst limiter: max 5 requests per 10 seconds per IP
   - Daily limiter: max 50 requests per 24 hours per IP
   - Per-device hard cap: max 100 messages per server session, 429 after that

2. AUTHENTICATION
   - x-app-secret header check against APP_SECRET environment variable
   - x-device-token header check against registered devices Set
   - /register endpoint must be exempt from device token check
   - All error responses must be on-brand and funny (see tone below)

3. INPUT VALIDATION on /chat endpoint
   - messages must be an array
   - Maximum 30 messages per request
   - Maximum 500 characters per message content
   - Role must be exactly "user" or "assistant"

4. TOKEN COST PROTECTION
   - max_tokens must be 300
   - Model must be claude-haiku-4-5-20251001 (cheapest)
   - Warn in console if a device exceeds 20 messages in a session

5. GENERAL
   - No stack traces or internal errors exposed to client
   - CORS configured correctly for mobile app (not wildcard * in production)
   - All secrets via environment variables, nothing hardcoded

ERROR RESPONSE TONE — all error messages should be funny and on-brand:
- Rate limited: "Easy there. Come back tomorrow with more stories."
- Burst limited: "Slow down babe."
- Unauthorized: "Nope."
- Message too long: "Summarise babe, I have questions."
- Too many messages: "That is a LOT of debrief."
- Server error: "Jess is having a moment, try again"
- Daily device cap hit: "You've had quite the day. Come back tomorrow."

Return the complete updated server.js with all security layers applied. Then list every change you made and why.
