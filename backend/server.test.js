
const request = require('supertest');
const { app, server, registeredDevices } = require('./server');

// Mock the Anthropic client
jest.mock('@anthropic-ai/sdk', () => {
  return {
    Anthropic: jest.fn().mockImplementation(() => {
      return {
        messages: {
          create: jest.fn().mockResolvedValue({
            content: [{ text: 'Hello from Jess' }],
          }),
        },
      };
    }),
  };
});

afterAll((done) => {
  server.close(done);
});

describe('API Endpoints', () => {
  describe('GET /health', () => {
    it('should return 200 OK', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toEqual(200);
      expect(res.body).toEqual({ status: 'Jess is ready and waiting' });
    });
  });

  describe('POST /register', () => {
    it('should register a new device', async () => {
      const deviceToken = 'test-device-token';
      const res = await request(app)
        .post('/register')
        .send({ deviceToken });
      expect(res.statusCode).toEqual(200);
      expect(res.body).toEqual({ status: 'Device registered' });
      expect(registeredDevices.has(deviceToken)).toBe(true);
    });

    it('should return 400 if deviceToken is missing', async () => {
      const res = await request(app).post('/register').send({});
      expect(res.statusCode).toEqual(400);
    });
  });

  describe('POST /chat', () => {
    const deviceToken = 'test-device-for-chat';
    const appSecret = process.env.APP_SECRET;

    beforeAll(async () => {
      // Register the device before chat tests
      await request(app).post('/register').send({ deviceToken });
    });

    it('should return 401 without an app secret', async () => {
      const res = await request(app)
        .post('/chat')
        .set('x-device-token', deviceToken)
        .send({ messages: [{ role: 'user', content: 'hi' }] });
      expect(res.statusCode).toEqual(401);
    });

    it('should return 401 with an invalid app secret', async () => {
      const res = await request(app)
        .post('/chat')
        .set('x-app-secret', 'invalid-secret')
        .set('x-device-token', deviceToken)
        .send({ messages: [{ role: 'user', content: 'hi' }] });
      expect(res.statusCode).toEqual(401);
    });

    it('should return 401 without a device token', async () => {
      const res = await request(app)
        .post('/chat')
        .set('x-app-secret', appSecret)
        .send({ messages: [{ role: 'user', content: 'hi' }] });
      expect(res.statusCode).toEqual(401);
    });

    it('should return 401 with an unregistered device token', async () => {
      const res = await request(app)
        .post('/chat')
        .set('x-app-secret', appSecret)
        .set('x-device-token', 'unregistered-device')
        .send({ messages: [{ role: 'user', content: 'hi' }] });
      expect(res.statusCode).toEqual(401);
    });

    it('should return 200 with a valid request', async () => {
      const res = await request(app)
        .post('/chat')
        .set('x-app-secret', appSecret)
        .set('x-device-token', deviceToken)
        .send({ messages: [{ role: 'user', content: 'hi' }] });
      expect(res.statusCode).toEqual(200);
      expect(res.body).toEqual({ reply: 'Hello from Jess' });
    });

    it('should return 400 for invalid message format', async () => {
      const res = await request(app)
        .post('/chat')
        .set('x-app-secret', appSecret)
        .set('x-device-token', deviceToken)
        .send({ messages: [{ role: 'invalid-role', content: 'hi' }] });
      expect(res.statusCode).toEqual(400);
    });

    it('should return 400 for messages over the length limit', async () => {
      const longMessage = 'a'.repeat(501);
      const res = await request(app)
        .post('/chat')
        .set('x-app-secret', appSecret)
        .set('x-device-token', deviceToken)
        .send({ messages: [{ role: 'user', content: longMessage }] });
      expect(res.statusCode).toEqual(400);
    });

    it('should return 400 for too many messages', async () => {
      const tooManyMessages = Array(31).fill({ role: 'user', content: 'hi' });
      const res = await request(app)
        .post('/chat')
        .set('x-app-secret', appSecret)
        .set('x-device-token', deviceToken)
        .send({ messages: tooManyMessages });
      expect(res.statusCode).toEqual(400);
    });
  });
});
