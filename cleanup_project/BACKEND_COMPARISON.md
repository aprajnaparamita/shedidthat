# Backend vs Local Server Implementation Comparison

This document provides a side-by-side comparison of the Cloudflare Worker backend and the local Dart server to highlight discrepancies.

## 🔀 Request Flow Comparison

### Production Mode (Cloudflare Worker)
```
User Message 
  ↓
Flutter API Service
  ↓ POST /chat with {"messages": [...]}
Cloudflare Worker (server.js)
  ↓ CORS middleware
  ↓ Auth middleware (check secret & device)
  ↓ Rate limit middleware (15 min window)
  ↓ Extract messages from body
  ↓ Call DeepSeek API (NO streaming)
  ↓ Get full response
  ↓ Split into word chunks
  ↓ Stream chunks back (50ms delay each)
  ↓ Send {done: true, speechUrl}
  ↓ Start TTS generation in background
  ↓
TTS Cache (Cloudflare KV, 60s TTL)
  ↓
GET /api/speech/:uuid (polls up to 10s)
  ↓
Flutter plays audio
```

### Local Mode (Dart Server)
```
User Message
  ↓
Flutter API Service
  ↓ POST /chat with {"messages": [...]} ❌ But server expects "messageHistory"!
Local Dart Server (local_server.dart)
  ↓ Logging middleware
  ↓ Rate limit middleware (1 hour window) ❌ Different window!
  ↓ Auth middleware (check hardcoded secret)
  ↓ Extract messageHistory from body ❌ Wrong key!
  ↓ Call DeepSeek API (WITH streaming)
  ↓ Forward chunks as received
  ↓ Parse DeepSeek SSE format
  ↓ Send {done: true, speechUrl}
  ↓ Start TTS generation
  ↓
TTS Cache (In-memory Map, no expiration) ❌ Memory leak!
  ↓
GET /api/speech/:uuid (polls up to 10s, 1s interval)
  ↓
Flutter plays audio
```

## 📊 Feature Parity Matrix

| Feature | Backend (server.js) | Local Server (local_server.dart) | Status |
|---------|---------------------|----------------------------------|--------|
| **Authentication** |
| App Secret Check | ✅ `c.env.APP_SECRET` | ✅ `'a-super-secret-key'` | ⚠️ Hardcoded in local |
| Device Registration | ✅ KV Store | ✅ In-memory Map | ✅ Works |
| Device Validation | ✅ Checks KV | ✅ Checks Map | ✅ Works |
| **Chat Endpoint** |
| Parameter Name | `messages` | `messageHistory` | ❌ MISMATCH |
| Streaming Method | Manual word-chunking | DeepSeek native | ❌ DIFFERENT |
| Typing Delay | 50ms per chunk | None (instant) | ❌ DIFFERENT UX |
| Response Format | SSE `data: {...}\n\n` | SSE `data: {...}\n\n` | ✅ Same |
| **Rate Limiting** |
| Window Duration | 15 minutes | 60 minutes | ❌ DIFFERENT |
| Max Requests | 100 | 100 | ✅ Same |
| Storage | KV with TTL | In-memory Map | ⚠️ Different |
| **TTS (Text-to-Speech)** |
| English Voice | en-US-Journey-F | en-US-Studio-O | ❌ DIFFERENT |
| Thai Voice | th-TH-Neural2-C | en-US-Studio-O | ❌ WRONG! |
| Chinese Voice | cmn-CN-Wavenet-D | en-US-Studio-O | ❌ WRONG! |
| Speaking Rate | 1.1 | 1.0 (default) | ❌ MISSING |
| Cache TTL | 60 seconds | ∞ (never expires) | ❌ MEMORY LEAK |
| Polling Interval | 200ms | 1000ms | ❌ SLOWER |
| Max Wait Time | 10s | 10s | ✅ Same |
| **Persona/Character** |
| English Persona | 4790 bytes from .md | "helpful assistant" | ❌ WRONG |
| Thai Persona | 9965 bytes from .md | "speaks Thai" | ❌ WRONG |
| Chinese Persona | 4100 bytes from .md | Not implemented | ❌ MISSING |
| **Error Handling** |
| Sentry Integration | ✅ Toucan-js | ❌ None | ❌ MISSING |
| Error Responses | JSON with messages | JSON with messages | ✅ Same |
| Crash Reporting | ✅ Sentry | ❌ Console only | ❌ MISSING |
| **Middleware Order** |
| 1st | CORS | Logging | ❌ DIFFERENT |
| 2nd | Auth | Rate Limit | ❌ DIFFERENT |
| 3rd | Rate Limit | Auth | ❌ DIFFERENT |
| **Endpoints** |
| GET / | ✅ Health check | ✅ Health check | ✅ Same |
| POST /register | ✅ Implemented | ✅ Implemented | ✅ Works |
| POST /chat | ✅ Implemented | ✅ Implemented | ⚠️ Bugs |
| GET /api/speech/:uuid | ✅ Implemented | ✅ Implemented | ⚠️ Different |
| GET /sentrytest | ✅ Implemented | ❌ Missing | ❌ MISSING |

## 🔍 Code-Level Differences

### 1. Chat Parameter Extraction

**Backend (server.js:204):**
```javascript
const { messages: messageHistory } = await c.req.json();
```
Expects: `{"messages": [...]}`

**Local Server (local_server.dart:119):**
```dart
final messageHistory = params['messageHistory'] as List<dynamic>;
```
Expects: `{"messageHistory": [...]}`

**Frontend Sends (api_service.dart:106):**
```dart
request.body = jsonEncode({'messages': messages.map((m) => m.toJson()).toList()});
```
Sends: `{"messages": [...]}`

**Result:** ✅ Backend works | ❌ Local server crashes

---

### 2. AI Streaming Approach

**Backend (server.js:218-245):**
```javascript
// Call DeepSeek WITHOUT streaming
const deepseekResponse = await fetch('https://api.deepseek.com/chat/completions', {
  method: 'POST',
  headers: { ... },
  body: JSON.stringify({
    model: 'deepseek-chat',
    messages: [systemMessage, ...messageHistory],
    max_tokens: 1024,
    // NOTE: stream is NOT set to true
  })
});

const msg = await deepseekResponse.json();
const fullMessage = msg.choices[0].message.content;

// Then manually split and stream
const chunks = fullMessage.match(/\S+\s*/g) || [fullMessage];
for (const chunk of chunks) {
  await writer.write(encoder.encode(`data: ${JSON.stringify({ content: chunk })}\n\n`));
  await new Promise(resolve => setTimeout(resolve, 50)); // 50ms delay
}
```

**Local Server (local_server.dart:142-180):**
```dart
// Call DeepSeek WITH streaming
deepseekRequest.body = jsonEncode({
  'model': 'deepseek-chat',
  'messages': messages,
  'stream': true,  // ← STREAMING ENABLED
});

final responseStream = await deepseekRequest.send();

// Forward chunks directly
responseStream.stream.listen((chunk) {
  final decoded = utf8.decode(chunk);
  final lines = decoded.split('\n').where((line) => line.isNotEmpty);
  
  for (final line in lines) {
    if (line.startsWith('data: ')) {
      final data = line.substring(6);
      if (data == '[DONE]') { /* ... */ }
      // Parse and forward immediately, no delay
    }
  }
});
```

**Result:** Different UX - backend has "typing" effect, local is instant bursts

---

### 3. Rate Limiting Window

**Backend (server.js:78):**
```javascript
const windowMs = 15 * 60 * 1000;  // 15 minutes
```

**Local Server (local_server.dart:95):**
```dart
final windowStart = now - (60 * 60 * 1000); // 1 hour
```

**Result:** Local mode users get 4x longer window (less restrictive)

---

### 4. TTS Voice Selection

**Backend (server.js:103-107):**
```javascript
const VOICES = {
  en: { languageCode: 'en-US', name: 'en-US-Journey-F' },
  th: { languageCode: 'th-TH', name: 'th-TH-Neural2-C' },
  zh: { languageCode: 'cmn-CN', name: 'cmn-CN-Wavenet-D' }
};

// In handleTTS:
const voice = VOICES[lang] || VOICES.en;
```

**Local Server (local_server.dart:211):**
```dart
'voice': {'languageCode': 'en-US', 'name': 'en-US-Studio-O'},
// ↑ Hardcoded! No lang parameter!
```

**Result:** All languages use English voice in local mode

---

### 5. Persona Content

**Backend (server.js:4-10):**
```javascript
import personaEN from './persona.en.md';
import personaZH from './persona.zh.md';
import personaTH from './persona.th.md';

const PERSONAS = {
  EN: personaEN,  // ~4.7KB of character definition
  ZH: personaZH,  // ~4.1KB
  TH: personaTH,  // ~9.9KB
};
```

**Local Server (local_server.dart:219-224):**
```dart
String _getPersona(String lang) {
  const personas = {
    'en': 'You are a helpful assistant.',  // Generic!
    'th': 'You are a helpful assistant who speaks Thai.',
  };
  return personas[lang] ?? personas['en']!;
}
```

**Result:** Completely different AI personality in local mode

---

### 6. Middleware Pipeline Order

**Backend (server.js:203):**
```javascript
app.post('/chat', authMiddleware, rateLimitMiddleware, async (c) => {
```
Order: Auth → Rate Limit → Handler

**Local Server (local_server.dart:58-61):**
```dart
final protectedHandler = const Pipeline()
    .addMiddleware(logRequests())      // 1
    .addMiddleware(_rateLimitMiddleware())  // 2
    .addMiddleware(_authMiddleware())  // 3
    .addHandler(protectedRouter);      // 4
```
Order: Logging → Rate Limit → Auth → Handler

**Note:** Shelf middleware runs bottom-to-top for request path, so actual order is:
Auth (3) → Rate Limit (2) → Logging (1) → Handler (4)

Wait, that's backwards from what I thought! Let me verify...

Actually in Shelf, `Pipeline` applies middleware in the order listed, so:
Request → Logging → Rate Limit → Auth → Handler

**Result:** Different order can cause unauthorized requests to consume rate limit quota

---

## 🎯 Impact Summary

### Critical Issues (App Breaking):
1. **Parameter mismatch** - Local mode doesn't work at all
2. **Server startup timing** - Race condition on first use

### High Impact (Bad UX):
3. **Wrong persona** - AI doesn't have Jess's personality
4. **Wrong TTS voices** - Thai/Chinese hear English voice
5. **Streaming differences** - Inconsistent chat feel

### Medium Impact (Confusing):
6. **Rate limit differences** - Different limits per mode
7. **Memory leak** - Speech cache never expires
8. **No error tracking** - Can't debug local mode issues

### Low Impact (Edge cases):
9. **Voice name differences** - Slightly different English voices
10. **Polling intervals** - Slightly slower in local mode
11. **Missing endpoints** - /sentrytest not implemented

## 🔧 Recommended Alignment Strategy

### Phase 1: Fix Showstoppers
- [ ] Change `messageHistory` → `messages` in local server
- [ ] Start local server in main.dart
- [ ] Add TTS lang parameter support

### Phase 2: Align Core Experience  
- [ ] Embed persona files in local server
- [ ] Standardize rate limit to 15 minutes
- [ ] Add speech cache expiration

### Phase 3: Align Streaming
Two options:
- **Option A:** Make backend stream from DeepSeek (more efficient)
- **Option B:** Make local server do word-chunking (consistent UX)

Recommend Option A for better performance.

### Phase 4: Production Hardening
- [ ] Add error handling to isolate
- [ ] Add Sentry to local mode (optional)
- [ ] Fix middleware ordering
- [ ] Add proper secret management

---

*Generated: 2026-02-27 04:13:08 GMT+7*
