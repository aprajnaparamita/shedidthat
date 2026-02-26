# Critical Bug Fixes - Quick Reference

> ✅ **STATUS: ALL FIXES APPLIED** — 2026-02-27

---

## 🔴 BUG-001: API Parameter Mismatch ✅ FIXED

**File:** `frontend/lib/local_server/local_server.dart`  
**Line:** 119

**Changed from:**
```dart
final messageHistory = params['messageHistory'] as List<dynamic>;
```

**Changed to:**
```dart
final messageHistory = params['messages'] as List<dynamic>;
```

**Why:** Frontend sends `messages`, backend expects `messages`, but local server expected `messageHistory`. This caused local mode to completely fail.

---

## 🔴 BUG-003: Local Server Not Started on Launch ✅ FIXED

**File:** `frontend/lib/main.dart`  
**Lines:** 23-32

**Changed from:**
```dart
if (isLocalMode && hasBeenRun) {

    }
```

**Changed to:**
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

## 🟠 BUG-004: Duplicate Server Instances / No Timeout ✅ FIXED

**File:** `frontend/lib/services/local_server_manager.dart`

**Changes made:**
- `return Future.value()` → `return` (cleaner early exit)
- Added 10-second startup timeout via `Timer`
- Added `error:` message handling from the isolate

```dart
// Timeout added:
Timer(const Duration(seconds: 10), () {
  if (!completer.isCompleted) {
    completer.completeError('Server startup timed out after 10 seconds');
  }
});

// Error handling added in listener:
} else if (message is String && message.startsWith('error:')) {
  if (!completer.isCompleted) {
    completer.completeError(message);
  }
}
```

---

## 🟡 BUG-005: Wrong Rate Limit Window ✅ FIXED

**File:** `frontend/lib/local_server/local_server.dart`  
**Line:** 95

**Changed from:**
```dart
final windowStart = now - (60 * 60 * 1000); // 1 hour window
```

**Changed to:**
```dart
final windowStart = now - (15 * 60 * 1000); // 15 minutes window (matches backend)
```

---

## 🟡 BUG-006: Wrong AI Persona (Generic Instead of Jess) ✅ FIXED

**File:** `frontend/lib/local_server/local_server.dart`  
**Function:** `_getPersona()`

**Changed from:**
```dart
String _getPersona(String lang) {
  const personas = {
    'en': 'You are a helpful assistant.',
    'th': 'You are a helpful assistant who speaks Thai.',
  };
  return personas[lang] ?? personas['en']!;
}
```

**Changed to:** Full Jess persona content for `en`, `th`, and `zh`, sourced directly from `backend/persona.en.md`, `backend/persona.th.md`, and `backend/persona.zh.md`. See `local_server.dart` for the embedded strings.

---

## 🟡 BUG-007: TTS Always English Voice ✅ FIXED

**File:** `frontend/lib/local_server/local_server.dart`

**Changes:**

1. Added a `_voices` constant map at class level:
```dart
static const Map<String, Map<String, String>> _voices = {
  'en': {'languageCode': 'en-US', 'name': 'en-US-Journey-F'},
  'th': {'languageCode': 'th-TH', 'name': 'th-TH-Neural2-C'},
  'zh': {'languageCode': 'cmn-CN', 'name': 'cmn-CN-Wavenet-D'},
};
```

2. Updated `_handleTTS` signature to accept `lang`:
```dart
Future<void> _handleTTS(String text, String uuid, String lang) async {
  final voice = _voices[lang] ?? _voices['en']!;
  // ... uses voice map instead of hardcoded en-US
  // ... also adds speakingRate: 1.1
}
```

3. Updated call site in `_handleChat` to pass `lang`:
```dart
_handleTTS(fullMessage, speechUuid, lang);
```

---

## 🔵 BUG-011: Dead Code Removed ✅ FIXED

**File:** `frontend/lib/services/api_service.dart`

**Removed:**
```dart
static String get _baseUrl => kDebugMode ? _localBaseUrl : _prodBaseUrl;
```

This getter was never used (all calls go through `getBaseUrl()` async method) and silently used the wrong URL in release builds.

---

## 🔵 BUG-012: Test Fixture Parameter Fixed ✅ FIXED

**File:** `frontend/test/fixtures/server_test_cases.json`  
**Line:** 12

**Changed from:**
```json
"body": {
  "messageHistory": [
```

**Changed to:**
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

1. ~~Fix BUG-001 (parameter mismatch)~~ ✅ Done
2. ~~Fix BUG-003 (server startup)~~ ✅ Done
3. ~~Fix BUG-004 (duplicate instances + timeout)~~ ✅ Done
4. ~~Fix BUG-005 (rate limit window)~~ ✅ Done
5. ~~Fix BUG-006 (personas)~~ ✅ Done
6. ~~Fix BUG-007 (TTS languages)~~ ✅ Done
7. ~~Fix BUG-011 (dead code)~~ ✅ Done
8. ~~Fix BUG-012 (test fixture)~~ ✅ Done
9. **Next:** Test thoroughly in local mode
10. **Next:** Security review for SEC-001 and SEC-002

---

## ⚠️ Known Remaining Issues

Even after these fixes, the following still need attention:

- **BUG-002:** Streaming implementation differences between local/prod — needs bigger refactor
- **BUG-008:** Speech cache never expires in local mode — memory leak over time
- **ISSUE-001:** Middleware ordering differences between backends
- **ISSUE-002:** Missing error handling in server isolate entry point
- **SEC-001 / SEC-002:** Hardcoded secrets (`_appSecret`) — needs proper secret management

These should be addressed in follow-up sprints.

---

*Last updated: 2026-02-27 — All critical, high, and medium bugs fixed*
