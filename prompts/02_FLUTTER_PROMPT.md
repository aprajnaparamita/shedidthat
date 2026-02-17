# Prompt 2 — Flutter App

Paste this entire prompt into your local Claude instance.

---

You are building the Flutter frontend for a comedy app called "She Absolutely Just Did That" — a post-sex debrief chatbot for lesbian and queer women. The backend is an Express.js server on Fly.io. The chatbot character is named Jess.

IMPORTANT CONSTRAINTS:
- All conversations stored locally on device only using SharedPreferences
- No user accounts, no login, no remote database
- The full conversation history is sent to the backend on every message — this is intentional, it gives Jess her memory via Claude's context window
- Backend URL will be: https://she-absolutely-just-did-that-api.fly.dev

CREATE THESE FILES:

1. pubspec.yaml
2. lib/main.dart
3. lib/models/message.dart
4. lib/services/api_service.dart
5. lib/services/storage_service.dart
6. lib/services/device_service.dart
7. lib/screens/home_screen.dart
8. lib/screens/chat_screen.dart

DEPENDENCIES TO USE:
- http: ^1.2.0
- shared_preferences: ^2.2.2
- uuid: ^4.3.3
- device_info_plus: ^9.1.0
- crypto: ^3.0.3
- cupertino_icons: ^1.0.6

MESSAGE MODEL (message.dart):
- Fields: role (String), content (String), timestamp (DateTime)
- toJson() method: returns only {role, content} — no timestamp, this goes to the API
- toStorage() method: returns {role, content, timestamp as ISO8601 string}
- fromStorage() factory constructor

STORAGE SERVICE (storage_service.dart):
- newConversation(): creates UUID, adds to index, returns the ID
- saveConversation(String id, List<Message> messages): saves full message list as JSON
- loadConversation(String id): returns List<Message>
- getAllConversationIds(): returns List<String>, most recent first
- getConversationPreview(String id): returns first user message truncated to 50 chars
- deleteConversation(String id): removes from storage and index
- clearAll(): wipes everything

DEVICE SERVICE (device_service.dart):
- getDeviceToken(): returns a stable SHA-256 hash of the device hardware ID
  - On Android: use androidInfo.id
  - On iOS: use iosInfo.identifierForVendor
  - Cache the result in SharedPreferences under 'device_token'
  - Format the hash as: sha256(utf8('she-absolutely:' + deviceId)).toString()
- registerDevice(): calls POST /register on the backend with the device token
  - Only register once — cache a boolean 'device_registered' in SharedPreferences
  - Call this on app first launch

API SERVICE (api_service.dart):
- Static method: sendMessage(List<Message> messages, String deviceToken)
- Sends POST /chat with full messages array
- Headers must include:
  - Content-Type: application/json
  - x-app-secret: hardcoded shared secret (use placeholder 'REPLACE_WITH_YOUR_SECRET')
  - x-device-token: the device token
- Handle 429 responses with message: "Easy there! Come back tomorrow with more stories."
- Handle other errors with: "Jess is having a moment — try again"

HOME SCREEN (home_screen.dart):
- Shows list of past conversations
- Each item shows: preview text + relative timestamp (e.g. "2 hours ago")
- Tapping opens the chat screen with that conversation loaded
- FAB or button to start a new conversation
- Swipe to delete a conversation
- Empty state with a fun message like "No debriefs yet. What are you waiting for?"
- App title: "She Absolutely Just Did That"

CHAT SCREEN (chat_screen.dart):
- Standard chat bubble UI
- User messages: right-aligned, purple/pink bubble
- Jess messages: left-aligned, light grey bubble, maybe with a small "J" avatar
- On first message of a new conversation: send an empty user message to trigger Jess's opening line, OR better — have the screen automatically fire off a request to get Jess's opening line when a new conversation starts (no user input needed to start)
- Loading indicator while waiting for Jess's response
- Text input with send button
- Disable input while waiting for response
- On each send: append user message to local storage, send full history to API, append Jess's reply to local storage, save again
- Handle errors gracefully with a retry option
- Back button saves the conversation automatically

DESIGN:
- Color palette: deep purple (#4A0E5C) and hot pink (#E91E8C) as primary colors
- Fun, warm, slightly chaotic energy
- Font: use Google Fonts if available, otherwise system fonts
- The app should feel like texting your wildest best friend, not a clinical health app

MAIN.DART:
- On app launch: call DeviceService.registerDevice() before showing any UI
- Show a simple splash or loading state while registering
- Then show HomeScreen
- MaterialApp with the purple/pink theme applied globally

After writing all files, provide a brief explanation of the conversation flow: how a new chat starts, how messages are saved, and how history works across sessions.
