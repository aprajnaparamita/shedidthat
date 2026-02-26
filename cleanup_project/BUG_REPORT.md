# Bug Report - She Absolutely Just Did That

Generated: 2026-02-27
Status: In Progress

## 🔴 CRITICAL BUGS

### BUG-001: API Parameter Name Mismatch Between Backends
**Severity:** CRITICAL  
**Location:** 
- `backend/server.js:204`
- `frontend/lib/local_server/local_server.dart:119`
- `frontend/lib/services/api_service.dart:106`

**Description:**
The Cloudflare backend and local server expect different parameter names for the message history:
- **Backend (server.js)**: Expects `messages` in request body, destructured as `messageHistory`
  ```javascript
  const { messages: messageHistory } = await c.req.json();
  ```
- **Local Server**: Expects `messageHistory` directly
  ```dart
  final messageHistory = params['messageHistory'] as List<dynamic>;
  ```
- **Frontend API Service**: Sends `messages`
  ```dart
  request.body = jsonEncode({'messages': messages.map((m) => m.toJson()).toList()});
  ```

**Impact:**
- ✅ Cloudflare backend works correctly
- ❌ Local server will crash with null exception when trying to access `messageHistory`
- Users in local mode cannot send chat messages

**Reproduction:**
1. Enable local mode
2. Attempt to send a chat message
3. Local server throws: "type 'Null' is not a subtype of type 'List<dynamic>'"

**Fix Required:**
Change local_server.dart line 119 from:
```dart
final messageHistory = params['messageHistory'] as List<dynamic>;
```
to:
```dart
final messageHistory = params['messages'] as List<dynamic>;
```

---

### BUG-002: Streaming Implementation Fundamentally Different
**Severity:** CRITICAL  
**Location:**
- `backend/server.js:218-273`
- `frontend/lib/local_server/local_server.dart:142-197`

**Description:**
The two backends implement streaming in completely different ways:

**Backend (Cloudflare Worker):**
1. Calls DeepSeek API without streaming (`stream: false` implied)
2. Waits for full response
3. Manually splits response into word chunks
4. Streams chunks with artificial 50ms delay
5. Sends `done: true` with speechUrl at the end

**Local Server:**
1. Calls DeepSeek API with `stream: true`
2. Forwards streaming chunks as they arrive
3. No artificial delay
4. Parses SSE format from DeepSeek
5. Sends `done: true` with speechUrl when sees `[DONE]`

**Impact:**
- Different user experience: Backend has typing effect, local server is instant bursts
- Different error handling paths
- Potential timing issues with TTS generation
- Frontend might see different chunk patterns

**Additional Issues Found:**
- Backend uses `data.match(/\S+\s*/g)` to split by words - simple but might break on special characters
- Local server tries to parse DeepSeek's raw SSE format which may have different structure
- Error handling is different: backend fails silently, local server prints errors

**Fix Required:**
Align both implementations to use the same approach (recommend: backend's word-chunking approach for consistent UX)

---

## 🟠 HIGH SEVERITY BUGS

### BUG-003: Local Server Not Started on App Launch
**Severity:** HIGH  
**Location:** `frontend/lib/main.dart:23-25`

**Description:**
```dart
if (isLocalMode && hasBeenRun) {
    // Empty block - no code!
}
```

The main.dart checks for local mode but does nothing. The local server is only started later in HomeScreen.initState(), creating a race condition.

**Impact:**
- If user navigates quickly to chat, server might not be ready
- Device registration might fail
- First message might timeout
- ~1-2 second delay before app is actually usable

**Reproduction:**
1. Enable local mode
2. Restart app
3. Quickly tap "Get Started" then "New Chat"
4. Try to send message immediately
5. Message fails or hangs

**Fix Required:**
Start local server in main.dart before showing HomeScreen:
```dart
if (isLocalMode && hasBeenRun) {
  final deepseekApiKey = await storageService.getDeepseekApiKey();
  final googleApiKey = await storageService.getGoogleApiKey();
  if (deepseekApiKey != null && googleApiKey != null) {
    await LocalServerManager().startServer(
      deepseekApiKey: deepseekApiKey,
      googleApiKey: googleApiKey,
    );
    await DeviceService.registerDevice();
  }
}
```

---

### BUG-004: Local Server Starts Duplicate Instances
**Severity:** HIGH  
**Location:** `frontend/lib/screens/home_screen.dart:40-52`

**Description:**
The HomeScreen._initServer() method starts the local server, but there's no check if it's already running:
```dart
if (deepseekApiKey != null && googleApiKey != null) {
  print('[HomeScreen] Waiting for local server to confirm startup...');
  await LocalServerManager().startServer(  // No check if already running!
    deepseekApiKey: deepseekApiKey,
    googleApiKey: googleApiKey,
  );
```

LocalServerManager.startServer() does have a check (`if (_serverIsolate != null)`), but it returns immediately without completing the future properly.

**Impact:**
- Multiple HomeScreen navigations might try to start server multiple times
- Port 8789 binding might fail
- Race conditions in isolate spawning
- Memory leak from orphaned isolates

**Fix Required:**
Make startServer() return early with proper completion:
```dart
if (_serverIsolate != null) {
  print('[LocalServerManager] Server is already running.');
  return Future.value(); // Add this return!
}
```

---

## 🟡 MEDIUM SEVERITY BUGS

### BUG-005: Rate Limiting Window Inconsistency
**Severity:** MEDIUM  
**Location:**
- `backend/server.js:78` - 15 minutes
- `frontend/lib/local_server/local_server.dart:95` - 1 hour

**Description:**
Different rate limit windows create inconsistent user experience.

**Backend:**
```javascript
const windowMs = 15 * 60 * 1000;  // 15 minutes
const maxRequests = 100;
```

**Local Server:**
```dart
final windowStart = now - (60 * 60 * 1000); // 1 hour window
if (record['count'] >= 100) {
```

**Impact:**
- Local mode users get 4x longer rate limit window
- Inconsistent behavior between modes
- Documentation/error messages would be wrong

**Fix Required:**
Standardize to 15 minutes in local_server.dart:
```dart
final windowStart = now - (15 * 60 * 1000); // 15 minutes
```

---

### BUG-006: Persona Content Mismatch
**Severity:** MEDIUM  
**Location:** `frontend/lib/local_server/local_server.dart:219-224`

**Description:**
Local server uses hardcoded minimal personas instead of loading the actual persona files:

```dart
String _getPersona(String lang) {
  const personas = {
    'en': 'You are a helpful assistant.',
    'th': 'You are a helpful assistant who speaks Thai.',
  };
  return personas[lang] ?? personas['en']!;
}
```

Meanwhile, backend loads rich persona files:
- `backend/persona.en.md` (4790 bytes)
- `backend/persona.th.md` (9965 bytes)  
- `backend/persona.zh.md` (4100 bytes)

**Impact:**
- Local mode has completely different AI personality
- Missing Jess character/tone
- Not "loudest, warmest, most obsessed best friend"
- Breaks core app experience

**Fix Required:**
Load persona files in Dart or embed them as assets

---

### BUG-007: TTS Voice Language Not Respected in Local Mode
**Severity:** MEDIUM  
**Location:** `frontend/lib/local_server/local_server.dart:208-215`

**Description:**
Local server always uses English voice regardless of language parameter:

```dart
Future<void> _handleTTS(String text, String uuid) async {
  // ... 
  body: jsonEncode({
    'input': {'text': text},
    'voice': {'languageCode': 'en-US', 'name': 'en-US-Studio-O'},  // Always English!
    'audioConfig': {'audioEncoding': 'MP3'},
  }),
}
```

Backend has proper language support:
```javascript
const VOICES = {
  en: { languageCode: 'en-US', name: 'en-US-Journey-F' },
  th: { languageCode: 'th-TH', name: 'th-TH-Neural2-C' },
  zh: { languageCode: 'cmn-CN', name: 'cmn-CN-Wavenet-D' }
};
```

**Impact:**
- Thai/Chinese users hear English voice reading translated text
- Weird/broken user experience
- TTS might fail to pronounce non-English text correctly

**Fix Required:**
Add lang parameter to _handleTTS and use appropriate voices

---

### BUG-008: Speech Cache Expiration Inconsistency  
**Severity:** MEDIUM  
**Location:**
- `backend/server.js:138` - 60 seconds TTL
- `frontend/lib/local_server/local_server.dart:121` - No expiration

**Description:**
Backend expires speech from KV cache after 60 seconds. Local server keeps it in memory map forever.

**Impact:**
- Memory leak in local mode for long sessions
- Inconsistent behavior if user tries to replay old audio
- Local mode might run out of memory with many conversations

**Fix Required:**
Add TTL or size limit to local speech cache

---

## 🔵 LOW SEVERITY BUGS

### BUG-009: Missing Chinese Persona in Local Server
**Severity:** LOW  
**Location:** `frontend/lib/local_server/local_server.dart:220-222`

**Description:**
Local server only has 'en' and 'th' personas, missing 'zh' (Chinese).

**Impact:**
- Chinese users fallback to English persona
- Language setting ignored

**Fix Required:**
Add Chinese persona to map

---

### BUG-010: Inconsistent Port Numbers in Comments/Logs
**Severity:** LOW  
**Location:** Multiple files

**Description:**
- local_server.dart uses port 8789
- api_service.dart mentions 8788 for wrangler
- Comments might reference wrong ports

**Impact:**
- Confusion during debugging
- Wrong port in error messages

**Fix Required:**
Audit and fix all port references

---

## 🔵 LOW SEVERITY BUGS (continued)

### BUG-011: Unused _baseUrl Getter
**Severity:** LOW  
**Location:** `frontend/lib/services/api_service.dart:31`

**Description:**
There's a synchronous `_baseUrl` getter that's never used:
```dart
static String get _baseUrl => kDebugMode ? _localBaseUrl : _prodBaseUrl;
```

All code uses the async `getBaseUrl()` method instead. This is dead code.

**Impact:**
- Code confusion
- Maintenance burden
- Could cause bugs if someone uses it by mistake (doesn't check isLocalMode properly)

**Fix Required:**
Remove the unused getter

---

### BUG-012: Test File Uses Wrong Parameter Name
**Severity:** LOW (test issue)  
**Location:** `frontend/test/fixtures/server_test_cases.json:12`

**Description:**
Test fixture uses `messageHistory` in the body:
```json
"body": {
  "messageHistory": [
```

But this is testing against the backend which expects `messages`. The test might pass because it's testing the local server (which incorrectly expects `messageHistory`).

**Impact:**
- Tests not catching the parameter mismatch bug
- False confidence in code correctness

**Fix Required:**
Change test to use `messages` parameter

---

### BUG-013: Missing Speaking Rate in Local Server TTS
**Severity:** LOW  
**Location:** `frontend/lib/local_server/local_server.dart:213`

**Description:**
Backend sets `speakingRate: 1.1` for TTS, local server doesn't:

**Backend:**
```javascript
audioConfig: { audioEncoding: 'MP3', speakingRate: 1.1 }
```

**Local Server:**
```dart
'audioConfig': {'audioEncoding': 'MP3'},
```

**Impact:**
- Slightly different audio speed between modes
- Minor UX inconsistency

**Fix Required:**
Add speakingRate to local server TTS config

---

## 🟣 DESIGN/ARCHITECTURAL ISSUES

### ISSUE-001: Middleware Ordering Inconsistency
**Severity:** MEDIUM  
**Location:** 
- `backend/server.js:203` 
- `frontend/lib/local_server/local_server.dart:58-61`

**Description:**
Middleware is applied in different order:

**Backend (Hono):**
```javascript
app.post('/chat', authMiddleware, rateLimitMiddleware, async (c) => {
```
Order: auth → rate limit → handler

**Local Server (Shelf):**
```dart
final protectedHandler = const Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(_rateLimitMiddleware())
    .addMiddleware(_authMiddleware())
    .addHandler(protectedRouter);
```
Order: logging → rate limit → auth → handler

**Impact:**
- Rate limiting applied to unauthorized requests in local mode
- Could be exploited to fill rate limit cache
- Logging happens before auth in local mode only

**Fix Required:**
Align middleware order: logging → auth → rate limit

---

### ISSUE-002: No Error Handling in LocalServerManager
**Severity:** MEDIUM  
**Location:** `frontend/lib/services/local_server_manager.dart:25-42`

**Description:**
If server isolate crashes or fails to start, there's no error handling:
```dart
_receivePort!.listen((message) {
  if (message == 'started') {
    // ...
  }
  // But what if we receive an error message?
});
```

**Impact:**
- App might hang forever waiting for 'started' message
- No way to detect or recover from server startup failures
- Users stuck on loading screen

**Fix Required:**
Add timeout, error handling, and error messages from isolate

---

### ISSUE-003: Speech Cache Polling Inefficiency
**Severity:** LOW  
**Location:**
- `backend/server.js:144-161`
- `frontend/lib/local_server/local_server.dart:121-133`

**Description:**
Both implementations poll for audio with sleep loops:

**Backend:**
```javascript
const maxWait = 10000;  // 10 seconds
const interval = 200;   // Check every 200ms
// 50 polling attempts
```

**Local Server:**
```dart
for (int i = 0; i < 10; i++) {  // 10 seconds
  await Future.delayed(const Duration(seconds: 1));  // Check every 1 second
}
// Only 10 polling attempts
```

**Impact:**
- Inefficient (busy waiting)
- Local server has much coarser polling (1s vs 200ms)
- User might hear audio delay
- Better to use completion/future pattern

**Fix Required:**
Use Future/Promise for audio completion notification

---

### ISSUE-004: Missing CORS in Local Server
**Severity:** LOW (web platform only)  
**Location:** `frontend/lib/local_server/local_server.dart`

**Description:**
Backend has CORS middleware:
```javascript
app.use('/*', cors({
  origin: '*',
  allowHeaders: ['Content-Type', 'x-app-secret', 'x-device-id'],
  allowMethods: ['POST', 'GET', 'OPTIONS'],
}));
```

Local server has no CORS handling. This is fine for non-web platforms, but the comment says "loads on every platform except web".

**Impact:**
- None if local server truly never runs on web
- But code suggests web might use Cloudflare backend always
- Potential confusion

**Fix Required:**
Document platform matrix clearly

---

## 🔧 MISSING FEATURES / INCONSISTENCIES

### MISSING-001: No zh (Chinese) Support in Local Mode
**Severity:** MEDIUM  
**Location:** `frontend/lib/local_server/local_server.dart`

**Description:**
Backend supports 3 languages: EN, ZH, TH  
Local server only supports: EN, TH

Missing:
- Chinese persona
- Chinese TTS voice
- Fallback behavior not documented

**Impact:**
- Chinese users get English experience in local mode
- App appears to support Chinese but doesn't work properly

**Fix Required:**
Add Chinese support to local server

---

### MISSING-002: No Sentry in Local Mode
**Severity:** LOW  
**Location:** Multiple files

**Description:**
Backend has Sentry error tracking:
```javascript
app.use(async (c, next) => {
  const sentry = new Toucan({
    dsn: c.env.SENTRY_DSN,
```

Local server has no error tracking. Errors just print to console.

**Impact:**
- Can't debug local mode issues
- Missing crash reports
- Development/debugging harder

**Fix Required:**
Add Sentry or local error logging

---

### MISSING-003: No /sentrytest Endpoint in Local Server
**Severity:** LOW  
**Location:** `frontend/lib/local_server/local_server.dart`

**Description:**
Backend has `/sentrytest` endpoint for testing error reporting.  
Local server doesn't implement this.

**Impact:**
- Debug button in HomeScreen won't work in local mode
- Can't test error handling

**Fix Required:**
Add /sentrytest endpoint to local server (or disable button in local mode)

---

## 🔒 SECURITY ISSUES

### SEC-001: Hardcoded App Secret in Local Server
**Severity:** LOW (local mode only)  
**Location:** `frontend/lib/local_server/local_server.dart:17`

**Description:**
```dart
final String _appSecret = 'a-super-secret-key';
```

Secret is hardcoded and exposed in client code. Anyone can decompile the app and get it.

**Impact:**
- Low: only affects local mode where user controls both client and server
- But still bad practice
- Could be used to bypass checks if local server exposed on network

**Fix Required:**
Generate random secret on first run or accept via environment variable

---

### SEC-001: API Secret Exposed in Client
**Severity:** MEDIUM (production mode)  
**Location:** `frontend/lib/services/api_service.dart:33`

**Description:**
```dart
static const String _appSecret = String.fromEnvironment('APP_SECRET');
```

The production API secret must be compiled into the Flutter app, which can be decompiled.

**Impact:**
- Anyone can extract the secret and bypass device registration
- Rate limiting can be bypassed
- Potential abuse of API

**Fix Required:**
Consider different auth approach (device-specific tokens, OAuth, etc.)

---

## 📊 SUMMARY

### By Severity:
- 🔴 **CRITICAL**: 2 bugs (API mismatch, Streaming inconsistency)
- 🟠 **HIGH**: 2 bugs (Server not started, Duplicate instances)
- 🟡 **MEDIUM**: 6 bugs (Rate limit, Personas, TTS voices, Speech cache, Middleware order, Error handling)
- 🔵 **LOW**: 6 bugs (Chinese persona, Port comments, Dead code, Test params, Speaking rate, CORS)
- 🟣 **DESIGN**: 4 issues (Middleware order, Error handling, Polling, CORS)
- 🔒 **SECURITY**: 2 issues (Hardcoded secrets)

### Total Issues: 22

### Must-Fix for Production:
1. BUG-001 - API parameter mismatch (app won't work in local mode)
2. BUG-003 - Local server not started on launch (race condition)
3. BUG-006 - Persona mismatch (wrong AI personality)
4. BUG-007 - TTS language not respected (wrong voice)
5. ISSUE-002 - No error handling (app hangs on failures)
6. SEC-002 - API secret in client (security risk)

### Recommended Fixes:
1. All MEDIUM severity bugs
2. Align streaming implementations
3. Add proper error handling
4. Fix Chinese support
5. Clean up dead code

---

## 📝 DETAILED REPRODUCTION STEPS

### Reproducing BUG-001 (API Parameter Mismatch):
```bash
# 1. Enable local mode in app settings
# 2. Ensure local server is configured with API keys
# 3. Try to send any chat message
# Expected: Server crashes with null pointer exception
# Error log: "type 'Null' is not a subtype of type 'List<dynamic>'"
```

### Reproducing BUG-003 (Server Not Started):
```bash
# 1. Enable local mode
# 2. Kill app completely
# 3. Launch app
# 4. Quickly tap "Get Started"
# 5. Immediately try to start a chat
# Expected: Chat request fails or times out
# Error: "Connection refused" or timeout
```

### Reproducing BUG-006 (Wrong Persona):
```bash
# 1. Enable local mode
# 2. Start a chat
# 3. Send: "Tell me about yourself"
# Expected in local mode: Generic "helpful assistant" response
# Expected in prod mode: Jess personality with enthusiasm and character
```

---

## 🔨 FIX PRIORITY

### Sprint 1 (Critical - Must fix before any release):
- [ ] BUG-001: Fix API parameter mismatch
- [ ] BUG-003: Start server in main.dart
- [ ] ISSUE-002: Add error handling to LocalServerManager

### Sprint 2 (High - Breaks core experience):
- [ ] BUG-002: Align streaming implementations
- [ ] BUG-004: Fix duplicate server instances
- [ ] BUG-006: Load proper personas in local server
- [ ] BUG-007: Fix TTS language support

### Sprint 3 (Medium - Quality/consistency):
- [ ] BUG-005: Standardize rate limit windows
- [ ] BUG-008: Add speech cache expiration
- [ ] ISSUE-001: Fix middleware ordering
- [ ] MISSING-001: Add Chinese support to local server

### Sprint 4 (Polish):
- [ ] All LOW severity bugs
- [ ] Security improvements
- [ ] Code cleanup
- [ ] Documentation

---

*Report generated: 2026-02-27 04:13:08 GMT+7*  
*Plan ID: PLAN-87733717*  
*Files analyzed: 15*  
*Total lines reviewed: ~2,500*
