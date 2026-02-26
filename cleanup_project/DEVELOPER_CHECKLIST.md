# Developer Checklist - Bug Fixes

Quick reference for implementing fixes. Check off each item as you complete it.

## 🔴 CRITICAL - Do These First

### [ ] BUG-001: Fix API Parameter Mismatch
**File:** `frontend/lib/local_server/local_server.dart`  
**Line:** 119  
**Change:**
```dart
// OLD:
final messageHistory = params['messageHistory'] as List<dynamic>;

// NEW:
final messageHistory = params['messages'] as List<dynamic>;
```
**Test:** Send a chat message in local mode - should work now

---

### [ ] BUG-003: Start Server on Launch
**File:** `frontend/lib/main.dart`  
**Lines:** 23-25  
**Change:**
```dart
// OLD:
if (isLocalMode && hasBeenRun) {

}

// NEW:
if (isLocalMode && hasBeenRun) {
  final deepseekApiKey = await storageService.getDeepseekApiKey();
  final googleApiKey = await storageService.getGoogleApiKey();
  if (deepseekApiKey != null && googleApiKey != null) {
    print('[Main] Starting local server...');
    await LocalServerManager().startServer(
      deepseekApiKey: deepseekApiKey,
      googleApiKey: googleApiKey,
    );
    print('[Main] Registering device...');
    await DeviceService.registerDevice();
    print('[Main] Local server ready.');
  }
}
```
**Test:** Restart app, immediately send chat - should work without delay

---

## 🟠 HIGH - Do These Next

### [ ] BUG-004: Add Server Startup Timeout
**File:** `frontend/lib/services/local_server_manager.dart`  
**Lines:** 25-42  
**Add timeout to prevent hanging:**
```dart
Future<void> startServer({
  required String deepseekApiKey,
  required String googleApiKey,
}) async {
  if (_serverIsolate != null) {
    print('[LocalServerManager] Server is already running.');
    return;
  }

  print('[LocalServerManager] Spawning server isolate...');
  final completer = Completer<void>();
  
  // ADD THIS: Timeout after 5 seconds
  Timer(Duration(seconds: 5), () {
    if (!completer.isCompleted) {
      print('[LocalServerManager] Server startup timeout!');
      completer.completeError('Server startup timeout');
    }
  });

  _receivePort = ReceivePort();
  
  // ADD THIS: Error handling for messages
  _receivePort!.listen((message) {
    if (message == 'started') {
      print('[LocalServerManager] Server started successfully.');
      if (!completer.isCompleted) {
        completer.complete();
      }
    } else if (message is String && message.startsWith('error:')) {
      print('[LocalServerManager] Server error: $message');
      if (!completer.isCompleted) {
        completer.completeError(message);
      }
    }
  });

  _serverIsolate = await Isolate.spawn(
    _serverEntryPoint,
    {
      'sendPort': _receivePort!.sendPort,
      'deepseekApiKey': deepseekApiKey,
      'googleApiKey': googleApiKey,
    },
  );

  return completer.future;
}
```
**Test:** Unplug network, try to start - should timeout gracefully

---

## 🟡 MEDIUM - Important for UX

### [ ] BUG-005: Fix Rate Limit Window
**File:** `frontend/lib/local_server/local_server.dart`  
**Line:** 95  
**Change:**
```dart
// OLD:
final windowStart = now - (60 * 60 * 1000); // 1 hour window

// NEW:
final windowStart = now - (15 * 60 * 1000); // 15 minutes window
```
**Test:** Make 100 requests in 15 minutes - should get rate limited

---

### [ ] BUG-006: Load Proper Personas
**File:** `frontend/lib/local_server/local_server.dart`  
**Lines:** 219-224  

**Option 1 - Quick (embed strings):**
```dart
String _getPersona(String lang) {
  const personas = {
    'en': '''
You are Jess — the friend who picks up on the first ring at midnight and says "I KNEW IT. Tell me everything."

You're loud, warm, deeply invested, and queer-culture fluent. You've been there. You get it. You're genuinely obsessed with the details. 

Core traits:
- ENTHUSIASTIC (lots of caps, exclamation points)
- Asks follow-up questions like a best friend, not a survey
- Validates constantly ("SHE KNEW THE PLAYLIST?? That's premeditated!")
- Never judges
- Sometimes gently reality-checks
- Ends conversations with a rating prompt (1-10 scale)

You speak like a text message. Short bursts. Energy. Warmth. You're here for this.
''',
    'th': '''[Copy full Thai persona from backend/persona.th.md]''',
    'zh': '''[Copy full Chinese persona from backend/persona.zh.md]''',
  };
  return personas[lang] ?? personas['en']!;
}
```

**Option 2 - Better (load from assets):**
1. Add to `frontend/pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/personas/
```

2. Copy persona files:
```bash
cp backend/persona.*.md frontend/assets/personas/
```

3. Load in LocalServer constructor (more complex, needs async initialization)

**Test:** Chat in local mode - Jess should have personality

---

### [ ] BUG-007: Fix TTS Language Support
**File:** `frontend/lib/local_server/local_server.dart`  

**Step 1:** Add voice mapping (add to class):
```dart
static const Map<String, Map<String, String>> _voices = {
  'en': {'languageCode': 'en-US', 'name': 'en-US-Journey-F'},
  'th': {'languageCode': 'th-TH', 'name': 'th-TH-Neural2-C'},
  'zh': {'languageCode': 'cmn-CN', 'name': 'cmn-CN-Wavenet-D'},
};
```

**Step 2:** Update _handleTTS signature (line ~198):
```dart
Future<void> _handleTTS(String text, String uuid, String lang) async {
```

**Step 3:** Use lang parameter (line ~208):
```dart
final voice = _voices[lang] ?? _voices['en']!;
final url = Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=$googleApiKey');
final response = await http.post(
  url,
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'input': {'text': text},
    'voice': voice,  // Use the language-specific voice
    'audioConfig': {
      'audioEncoding': 'MP3',
      'speakingRate': 1.1,  // Also add this!
    },
  }),
);
```

**Step 4:** Pass lang from _handleChat (line ~170):
```dart
final lang = request.url.queryParameters['lang'] ?? 'en';
// Later when calling:
_handleTTS(fullMessage, speechUuid, lang);  // Add lang parameter
```

**Test:** Switch to Thai in app - should hear Thai voice

---

### [ ] BUG-008: Add Speech Cache Expiration
**File:** `frontend/lib/local_server/local_server.dart`  
**Add expiration tracking:**

```dart
// Change cache structure (line ~19):
final Map<String, (List<int>, DateTime)> _speechCache = {};

// Update _handleTTS (line ~215):
final audioContent = base64Decode(body['audioContent']);
_speechCache[uuid] = (audioContent, DateTime.now());  // Store with timestamp

// Update _handleSpeechRequest (line ~124):
if (_speechCache.containsKey(uuid)) {
  final (audio, timestamp) = _speechCache[uuid]!;
  
  // Check if expired (60 seconds like backend)
  if (DateTime.now().difference(timestamp).inSeconds > 60) {
    _speechCache.remove(uuid);
    return Response.notFound('Speech expired');
  }
  
  _speechCache.remove(uuid);
  return Response.ok(audio, headers: {'Content-Type': 'audio/mpeg'});
}
```

**Test:** Wait 61 seconds after receiving speech - should get 404

---

## 🔵 LOW - Nice to Have

### [ ] BUG-009: Add Chinese Persona
Already covered in BUG-006

### [ ] BUG-011: Remove Dead Code
**File:** `frontend/lib/services/api_service.dart`  
**Line:** 31  
**Delete:**
```dart
static String get _baseUrl => kDebugMode ? _localBaseUrl : _prodBaseUrl;
```

---

### [ ] BUG-012: Fix Test Parameters
**File:** `frontend/test/fixtures/server_test_cases.json`  
**Line:** 12  
**Change:**
```json
// OLD:
"body": {
  "messageHistory": [

// NEW:
"body": {
  "messages": [
```

---

### [ ] BUG-013: Add Speaking Rate
Already covered in BUG-007

---

## 🟣 DESIGN ISSUES - Consider Later

### [ ] ISSUE-001: Fix Middleware Order
**File:** `frontend/lib/local_server/local_server.dart`  
**Lines:** 58-61  
**Change order to match backend:**
```dart
final protectedHandler = const Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(_authMiddleware())      // Auth first
    .addMiddleware(_rateLimitMiddleware())  // Rate limit second
    .addHandler(protectedRouter);
```

---

### [ ] ISSUE-002: Already covered in BUG-004

### [ ] ISSUE-003: Polling Inefficiency
Consider refactoring to use Completer instead of sleep loops

### [ ] ISSUE-004: CORS Documentation
Add comment explaining why no CORS in local server

---

## 🔒 SECURITY - Discuss with Team

### [ ] SEC-001: Hardcoded Local Secret
Consider generating random secret on first run

### [ ] SEC-002: API Secret in Client
Consider different auth approach for production

---

## ✅ Testing Checklist

After implementing fixes, test:

### Local Mode:
- [ ] Can start app and reach home screen
- [ ] Can send first chat message without delay
- [ ] Chat streaming works smoothly
- [ ] TTS plays in correct language (EN/TH/ZH)
- [ ] Jess has proper personality (enthusiastic, asks questions)
- [ ] Rate limit kicks in after 100 requests in 15 minutes
- [ ] Speech expires after 60 seconds
- [ ] Can restart app without crashes
- [ ] Multiple conversations work

### Production Mode:
- [ ] Still works (no regressions)
- [ ] Chat works
- [ ] TTS works
- [ ] Rate limiting works
- [ ] Device registration works

### Edge Cases:
- [ ] Kill app during chat - should handle gracefully
- [ ] Network loss during chat - should show error
- [ ] Invalid API keys - should show helpful message
- [ ] Server startup failure - should timeout and show error

---

## 📱 Device Testing

Test on:
- [ ] iOS Simulator
- [ ] iOS Real Device
- [ ] Android Emulator
- [ ] Android Real Device
- [ ] Web Browser (prod mode only)
- [ ] macOS Desktop
- [ ] Windows Desktop (if supported)

---

## 🚀 Deployment

### Before Deploying:
- [ ] All critical bugs fixed
- [ ] All high priority bugs fixed
- [ ] Tests pass (update tests first!)
- [ ] Manual testing complete
- [ ] Code reviewed by peer
- [ ] Secrets handled properly

### Deployment Steps:
1. [ ] Update version number in pubspec.yaml
2. [ ] Update changelog
3. [ ] Build release versions
4. [ ] Test release builds
5. [ ] Deploy backend (if changed)
6. [ ] Submit to app stores
7. [ ] Monitor error reports

---

## 📞 Need Help?

If you get stuck on any fix:
1. Check CRITICAL_FIXES.md for detailed code examples
2. Check BACKEND_COMPARISON.md for context
3. Check BUG_REPORT.md for full issue descriptions
4. Run the app and check console logs
5. Ask for help with specific error messages

---

**Estimated Time:**
- Critical fixes: 1 hour
- High priority: 2 hours
- Medium priority: 4 hours
- Low priority: 2 hours
- Testing: 3 hours
- **Total: ~12 hours** (1.5 days)

Good luck! 🚀
