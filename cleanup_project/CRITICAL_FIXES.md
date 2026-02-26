# Critical Bug Fixes - Quick Reference

## 🔴 BUG-001: API Parameter Mismatch (MUST FIX FIRST)

**File:** `frontend/lib/local_server/local_server.dart`  
**Line:** 119

**Change this:**
```dart
final messageHistory = params['messageHistory'] as List<dynamic>;
```

**To this:**
```dart
final messageHistory = params['messages'] as List<dynamic>;
```

**Why:** Frontend sends `messages`, backend expects `messages`, but local server expects `messageHistory`. This causes local mode to completely fail.

---

## 🔴 BUG-003: Local Server Not Started on Launch

**File:** `frontend/lib/main.dart`  
**Lines:** 23-25

**Change this:**
```dart
if (isLocalMode && hasBeenRun) {

    }
```

**To this:**
```dart
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

**Why:** Server was starting too late (in HomeScreen), causing race conditions when user navigates quickly.

---

## 🟠 BUG-004: Fix Duplicate Server Instances

**File:** `frontend/lib/services/local_server_manager.dart`  
**Line:** 24

**Change this:**
```dart
if (_serverIsolate != null) {
  print('[LocalServerManager] Server is already running.');
  return Future.value();
}
```

**To this:**
```dart
if (_serverIsolate != null) {
  print('[LocalServerManager] Server is already running.');
  return Future.value(); // This line was missing!
}
```

**Note:** Actually the return is there, but we need to ensure it returns immediately without hanging.

Better fix - change the completer logic:

```dart
Future<void> startServer({
  required String deepseekApiKey,
  required String googleApiKey,
}) async {
  if (_serverIsolate != null) {
    print('[LocalServerManager] Server is already running.');
    return; // Just return, don't create new completer
  }

  print('[LocalServerManager] Spawning server isolate...');
  final completer = Completer<void>();
  
  // Add timeout
  Timer(Duration(seconds: 5), () {
    if (!completer.isCompleted) {
      completer.completeError('Server startup timeout');
    }
  });

  _receivePort = ReceivePort();
  _serverIsolate = await Isolate.spawn(
    _serverEntryPoint,
    {
      'sendPort': _receivePort!.sendPort,
      'deepseekApiKey': deepseekApiKey,
      'googleApiKey': googleApiKey,
    },
  );

  _receivePort!.listen((message) {
    if (message == 'started') {
      print('[LocalServerManager] Received server started confirmation from isolate.');
      if (!completer.isCompleted) {
        completer.complete();
      }
    } else if (message is String && message.startsWith('error:')) {
      if (!completer.isCompleted) {
        completer.completeError(message);
      }
    }
  });

  return completer.future;
}
```

---

## 🟡 BUG-006: Load Proper Personas

**File:** `frontend/lib/local_server/local_server.dart`  
**Lines:** 219-224

**Option 1 - Quick Fix (use embedded strings):**

Copy the content from `backend/persona.en.md`, `backend/persona.th.md`, `backend/persona.zh.md` and embed them:

```dart
String _getPersona(String lang) {
  const personas = {
    'en': '''
[Paste full content of persona.en.md here]
''',
    'th': '''
[Paste full content of persona.th.md here]
''',
    'zh': '''
[Paste full content of persona.zh.md here]
''',
  };
  return personas[lang] ?? personas['en']!;
}
```

**Option 2 - Better Fix (load from assets):**

1. Add persona files to Flutter assets in `pubspec.yaml`:
```yaml
assets:
  - assets/personas/persona.en.md
  - assets/personas/persona.th.md
  - assets/personas/persona.zh.md
```

2. Copy persona files to `frontend/assets/personas/`

3. Update local_server.dart to load from assets (requires passing them in constructor)

---

## 🟡 BUG-007: Fix TTS Language Support

**File:** `frontend/lib/local_server/local_server.dart`  
**Function:** `_handleTTS`

**Add lang parameter and voice mapping:**

```dart
// Add this constant at class level
static const Map<String, Map<String, String>> _voices = {
  'en': {'languageCode': 'en-US', 'name': 'en-US-Journey-F'},
  'th': {'languageCode': 'th-TH', 'name': 'th-TH-Neural2-C'},
  'zh': {'languageCode': 'cmn-CN', 'name': 'cmn-CN-Wavenet-D'},
};

// Update _handleTTS signature
Future<void> _handleTTS(String text, String uuid, String lang) async {
  final googleApiKey = _googleApiKey;
  if (googleApiKey == null) {
    print('Google API key not found');
    return;
  }

  final voice = _voices[lang] ?? _voices['en']!;
  final url = Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=$googleApiKey');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'input': {'text': text},
      'voice': voice,
      'audioConfig': {
        'audioEncoding': 'MP3',
        'speakingRate': 1.1,  // Add this too!
      },
    }),
  );
  // ... rest of function
}
```

**Update the call site in _handleChat (line ~170):**

```dart
final lang = request.url.queryParameters['lang'] ?? 'en';
// ...
_handleTTS(fullMessage, speechUuid, lang);  // Add lang parameter
```

---

## 🟡 BUG-005: Fix Rate Limit Window

**File:** `frontend/lib/local_server/local_server.dart`  
**Line:** 95

**Change this:**
```dart
final windowStart = now - (60 * 60 * 1000); // 1 hour window
```

**To this:**
```dart
final windowStart = now - (15 * 60 * 1000); // 15 minutes window (matches backend)
```

---

## 🔵 BUG-011: Remove Dead Code

**File:** `frontend/lib/services/api_service.dart`  
**Line:** 31

**Remove this line:**
```dart
static String get _baseUrl => kDebugMode ? _localBaseUrl : _prodBaseUrl;
```

---

## 🔵 BUG-012: Fix Test Parameter

**File:** `frontend/test/fixtures/server_test_cases.json`  
**Line:** 12

**Change this:**
```json
"body": {
  "messageHistory": [
```

**To this:**
```json
"body": {
  "messages": [
```

---

## 📋 Testing Checklist After Fixes

- [ ] Local mode: Can send chat messages
- [ ] Local mode: Server starts before first chat attempt
- [ ] Local mode: TTS speaks in correct language (EN/TH/ZH)
- [ ] Local mode: Jess has proper personality (not generic assistant)
- [ ] Local mode: Rate limit matches production (15 min window)
- [ ] Local mode: Multiple app restarts don't crash
- [ ] Production mode: Still works (no regressions)
- [ ] Tests pass with corrected parameters

---

## 🚀 Deployment Order

1. Fix BUG-001 (parameter mismatch) - **CRITICAL**
2. Fix BUG-003 (server startup) - **CRITICAL**
3. Fix BUG-004 (duplicate instances) - **HIGH**
4. Test thoroughly in local mode
5. Fix BUG-006 (personas) - **MEDIUM but important for UX**
6. Fix BUG-007 (TTS languages) - **MEDIUM**
7. Fix BUG-005 (rate limit) - **MEDIUM**
8. Fix remaining LOW priority bugs
9. Security review for SEC-001 and SEC-002

---

## ⚠️ Known Remaining Issues After Critical Fixes

Even after these fixes, you'll still have:
- Streaming implementation differences (BUG-002) - needs bigger refactor
- Speech cache never expires in local mode (BUG-008)
- Middleware ordering differences (ISSUE-001)
- Missing error handling in isolate (ISSUE-002)
- Hardcoded secrets (SEC-001, SEC-002)

These should be addressed in follow-up sprints.

---

*Last updated: 2026-02-27 04:13:08 GMT+7*
