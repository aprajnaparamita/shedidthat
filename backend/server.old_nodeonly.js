const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { Anthropic } = require('@anthropic-ai/sdk');
const { MongoClient } = require('mongodb');
const Sentry = require("@sentry/node");

Sentry.init({
  dsn: process.env.SENTRY_API_KEY,
  sendDefaultPii: true,
});

if (process.env.NODE_ENV === 'test') {
  require('dotenv').config({ path: '.env.test' });
} else {
  require('dotenv').config();
}
const fs = require('fs');
const path = require('path');

const app = express();
const anthropicClient = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// MongoDB setup
const mongoClient = new MongoClient(process.env.MONGODB_URI);
let devicesCollection;

async function connectToDb() {
  try {
    await mongoClient.connect();
    const database = mongoClient.db('SheDidThat'); // You can name your DB here
    devicesCollection = database.collection('devices');
    console.log('Successfully connected to MongoDB Atlas.');
  } catch (error) {
    console.error('Failed to connect to MongoDB', error);
    process.exit(1);
  }
}

const usageTracker = new Map();

// Load persona once at startup
const SYSTEM_PROMPT = fs.readFileSync(path.join(__dirname, 'persona.md'), 'utf8');

// Middleware
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] Received ${req.method} request for ${req.url}`);
  next();
});

// App secret middleware
const appSecretMiddleware = (req, res, next) => {
  const receivedSecret = req.get('x-app-secret');
  const serverSecret = process.env.APP_SECRET;
  if (receivedSecret !== serverSecret) {
    return res.status(401).json({ error: 'Nope.' });
  }
  next();
};
app.use('/chat', appSecretMiddleware);

// Device token middleware
const deviceTokenMiddleware = async (req, res, next) => {
  const deviceToken = req.get('x-device-token');
  try {
    const device = await devicesCollection.findOne({ deviceToken });
    if (!device) {
      return res.status(401).json({ error: 'Nope.' });
    }
    next();
  } catch (error) {
    console.error('Error validating device token:', error);
    return res.status(500).json({ error: 'Server error during authentication.' });
  }
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
app.post('/register', async (req, res) => {
  const { deviceToken } = req.body;
  if (!deviceToken) {
    return res.status(400).json({ error: 'deviceToken required' });
  }
  try {
    const existingDevice = await devicesCollection.findOne({ deviceToken });
    if (existingDevice) {
      return res.status(200).json({ status: 'Device already registered' });
    }
    await devicesCollection.insertOne({ deviceToken, createdAt: new Date() });
    console.log(`[Server] Device ${deviceToken.substring(0, 10)}... registered in DB.`);
    res.status(200).json({ status: 'Device registered' });
  } catch (error) {
    console.error('Error during device registration:', error);
    res.status(500).json({ error: 'Could not register device.' });
  }
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

  const validMessages = messages.every(m =>
    m.role && ['user', 'assistant'].includes(m.role) && typeof m.content === 'string' && m.content.length <= 500
  );
  if (!validMessages) {
    return res.status(400).json({ error: 'Summarise babe, I have questions.' });
  }

  try {
    const response = await anthropicClient.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 300,
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

let server;

connectToDb().then(() => {
  server = app.listen(PORT, () => console.log(`Jess is live on port ${PORT}`));
});

// For testing purposes
module.exports = { app, server, mongoClient };
