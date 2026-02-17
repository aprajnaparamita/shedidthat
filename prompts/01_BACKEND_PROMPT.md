# Prompt 1 — Backend (server.js)

Paste this entire prompt into your local Claude instance.

---

You are building the backend for a comedy app called "She Absolutely Just Did That" — a post-sex debrief chatbot for lesbian and queer women. The chatbot character is named Jess, a loud loving best friend who wants to hear every detail.

Build a complete, production-ready Express.js backend with the following spec:

STACK:
- Node.js with Express
- @anthropic-ai/sdk for Claude API calls
- express-rate-limit for abuse prevention
- cors for Flutter app access

FILES TO CREATE:
1. server.js
2. persona.md
3. package.json
4. fly.toml

SERVER.JS REQUIREMENTS:
- Load persona.md once at startup as the Claude system prompt
- Single POST /chat endpoint that accepts { messages: [{role, content}] }
- Returns { reply: string }
- GET /health endpoint returning { status: "Jess is ready and waiting" }
- POST /register endpoint that accepts { deviceToken: string } and adds it to an in-memory Set of known devices
- All environment variables via process.env — ANTHROPIC_API_KEY, APP_SECRET, PORT

SECURITY LAYERS (implement all of these):

1. Burst rate limiter: 5 requests per 10 seconds per IP
2. Daily rate limiter: 50 requests per 24 hours per IP
3. App secret middleware: check x-app-secret header against APP_SECRET env var, return 401 if missing or wrong
4. Device token middleware: check x-device-token header against in-memory Set of registered devices, return 401 if not registered. Skip this check on the /register endpoint itself.
5. Input validation on /chat:
   - messages must be an array
   - max 30 messages
   - max 500 characters per message
   - role must be either "user" or "assistant"
6. Per-device usage tracking: in-memory counter per device token, log a warning if over 20 messages, hard cap at 100 messages per server session with 429 response
7. Claude model must be: claude-haiku-4-5-20251001
8. max_tokens: 300 (keep Jess snappy)

ERROR RESPONSES should be funny and on-brand. Examples:
- Rate limit: "Easy there. Come back tomorrow with more stories."
- Burst limit: "Slow down babe."
- Unauthorized: "Nope."
- Validation fail: "That is a LOT of debrief." or "Summarise babe, I have questions."
- Server error: "Jess is having a moment, try again"

PERSONA.MD — write a full character brief for Jess with these elements:
- She is the user's loud, loving, obsessed best friend who has been waiting by the phone
- She is warm, funny, uses ALL CAPS for emphasis, matches user energy exactly
- She deeply understands lesbian and queer women's culture
- She asks ONE great follow-up question per response, never a list
- She never judges, always validates
- She is NOT clinical, never uses medical language
- Max 4-5 sentences per response
- Responses are punchy, like texting not essay writing
- Include 6 varied opening lines she picks from randomly
- Include example mid-debrief questions she might ask naturally
- Include guidance on how to help users land on a final rating (1-10)
- Include good vs bad response examples showing the tone difference
- End of conversation should always be warm and validating

FLY.TOML REQUIREMENTS:
- App name: she-absolutely-just-did-that-api
- Region: ord
- auto_stop_machines: true
- auto_start_machines: true
- min_machines_running: 0
- internal_port: 8080
- force_https: true
- memory: 256mb
- shared CPU

PACKAGE.JSON:
- Include start and dev scripts
- engines: node >=18.0.0
- All required dependencies with current stable versions

After writing all files, provide the exact terminal commands to deploy to Fly.io in order, including how to set the environment secrets.
