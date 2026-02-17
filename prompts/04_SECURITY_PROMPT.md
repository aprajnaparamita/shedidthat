# Prompt 4 — Security Hardening

Paste this entire prompt into your local Claude instance to add or audit security on the backend.

---

I have an Express.js backend for a chatbot app called "She Absolutely Just Did That." Here is the current server.js:

[PASTE YOUR CURRENT SERVER.JS HERE]

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
