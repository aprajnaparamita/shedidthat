# Prompt 7 — Voice Feature (Touch-to-Talk + Google Cloud TTS)

Paste this entire prompt into your local Claude instance.

---

I have an existing Flutter app called "She Absolutely Just Did That" — a post-sex debrief chatbot for lesbian and queer women. The chatbot character is Jess, a loud warm best friend. The app already has a working chat UI with text input.

I need to add a complete voice feature with:
- Touch-to-talk button (hold to speak, release to send)
- Google Cloud Text-to-Speech for Jess's replies (routed through my Express backend)
- Device-native Speech-to-Text for user input (free, no API)

---

## BACKEND CHANGES (add to existing server.js)

Add a new POST /speak endpoint:

```
POST /speak
Headers: x-app-secret, x-device-token (same auth as /chat)
Body: { text: string }
Returns: audio/mpeg binary
```

Requirements:
- Use @google-cloud/text-to-speech npm package
- Voice: en-US-Neural2-F (warm, natural female voice)
- Audio encoding: MP3
- Speaking rate: 1.05 (slightly fast — chatty friend energy)
- Pitch: 1.5 (warm, friendly)
- Apply the same security middleware as /chat (app secret + device token check)
- Max text length: 500 characters (validate and return 400 if exceeded)
- Google credentials via GOOGLE_APPLICATION_CREDENTIALS environment variable
- Return the MP3 binary directly with Content-Type: audio/mpeg
- Add 'google-cloud/text-to-speech' to package.json dependencies

Also provide:
- The exact fly secrets command to set Google credentials as a Fly.io secret
- Instructions for getting Google Cloud TTS credentials (service account JSON)
- How to set GOOGLE_APPLICATION_CREDENTIALS to point to a JSON file on Fly.io

---

## FLUTTER CHANGES

### New dependency to add to pubspec.yaml:
- speech_to_text: ^6.6.0
- just_audio: ^0.9.36  (for playing the MP3 response from Google TTS)

### New file: lib/services/voice_service.dart

This service manages all voice functionality:

SPEECH TO TEXT (device native, free):
- initialize(): sets up SpeechToText instance, requests microphone permission
- startListening(onResult: Function(String)): begins listening, calls onResult with interim results as they come in so the UI can show live transcription
- stopListening(): stops mic, returns final transcribed text
- isListening getter: bool
- isAvailable getter: bool (false if device doesn't support STT or permission denied)

TEXT TO SPEECH via backend:
- speak(String text, String deviceToken): 
  - POST to /speak endpoint with text
  - Include x-app-secret and x-device-token headers
  - Receive MP3 bytes
  - Play audio using just_audio
  - Return a Future that completes when audio finishes playing
- stopSpeaking(): stops any currently playing audio
- isSpeaking getter: bool

Error handling:
- If STT not available: fail gracefully, show text input only
- If /speak endpoint fails: fail silently, just show text (don't break the app)
- If audio playback fails: fail silently

### Changes to lib/screens/chat_screen.dart

Replace or supplement the existing text input bar with a voice-capable input bar.

LAYOUT — bottom input area should have:
- Text input field (existing) — takes up most of the width
- A microphone button to the right of the text field
- When NOT listening: mic icon, hot pink (#E91E8C), circular
- When LISTENING: pulsing red circle with mic icon, animated
- Existing send button stays for text-only use

TOUCH TO TALK BEHAVIOR:
- User taps and HOLDS the mic button → startListening()
- While held: show pulsing red animation, show live transcription text appearing in the text field in real time as words are recognised
- User RELEASES the mic button → stopListening(), then immediately send the transcribed text as a message (same flow as tapping the send button)
- If transcription is empty on release: do nothing, reset UI
- If user holds less than 300ms: treat as accidental tap, do nothing

JESS AUTO-SPEAKS HER REPLIES:
- After receiving Jess's text reply from /chat, automatically call voice_service.speak()
- While Jess is speaking: show a small animated "Jess is talking..." indicator near her bubble
- Show a tap-to-skip button (small, subtle) that calls voice_service.stopSpeaking()
- After audio finishes (or is skipped): remove the indicator, re-enable input

VOICE MODE TOGGLE:
- Small speaker icon button in the AppBar (top right)
- Toggles voice mode on/off
- When OFF: mic button is greyed out, Jess's replies are not auto-spoken (text only)
- When ON: full voice experience
- Save this preference to SharedPreferences as 'voice_mode_enabled'
- Default: ON

### New widget: lib/widgets/mic_button.dart

A standalone reusable widget for the microphone button:
- Takes: isListening (bool), onHoldStart (VoidCallback), onHoldEnd (VoidCallback), isEnabled (bool)
- When isListening=true: red background, pulsing scale animation (scale between 1.0 and 1.2, duration 600ms, repeat)
- When isListening=false: hot pink (#E91E8C) background, mic_none icon
- When isEnabled=false: grey, no interaction
- Size: 48x48 circular button
- Use GestureDetector with onLongPressStart and onLongPressEnd

### New widget: lib/widgets/jess_speaking_indicator.dart

Shows when Jess's TTS audio is playing:
- Small pill-shaped container, light purple background
- Animated sound wave (3 vertical bars that animate up and down out of sync)
- Text: "Jess is talking..."
- Tap anywhere on it to skip/stop audio
- Appears below Jess's latest message bubble
- Animate in/out smoothly

---

## PERMISSIONS

### Android (android/app/src/main/AndroidManifest.xml)
Add:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS (ios/Runner/Info.plist)
Add:
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>She Absolutely Just Did That needs your mic so you can tell Jess everything.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Hold the mic button and spill. Jess is listening.</string>
```

---

## GOOGLE CLOUD SETUP INSTRUCTIONS

After writing all code, provide step-by-step instructions for:

1. Creating a Google Cloud project (free tier)
2. Enabling the Text-to-Speech API
3. Creating a service account and downloading the JSON key
4. Adding the JSON key to Fly.io as a secret:
   fly secrets set GOOGLE_APPLICATION_CREDENTIALS_JSON="$(cat your-key.json)"
5. How to read the JSON from the environment variable in server.js (since Fly.io secrets can't be file paths, the JSON content needs to be passed as a string and parsed)

Show the updated server.js snippet for initialising the TTS client from a JSON string env var:
```javascript
const credentials = JSON.parse(process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON);
const ttsClient = new textToSpeech.TextToSpeechClient({ credentials });
```

---

## WHAT NOT TO CHANGE

- Do not modify storage_service.dart — conversations still save locally only
- Do not modify the /chat endpoint
- Do not modify the existing message bubble UI
- Do not add any new backend storage or logging of voice content
- The persona.md is unchanged — Jess's personality comes through in text, TTS just reads it

---

After writing all files and changes, provide:
1. A summary of every file modified and every file created
2. The complete updated package.json with new dependency
3. The exact test flow to verify voice is working end to end
