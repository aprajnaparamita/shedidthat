Hi you genius Trae! Our code we have coded is an app with a Cloudflare Worker backend and a Flutter client. 
I need to implement a text-to-speech system with the following architecture:

## ARCHITECTURE OVERVIEW

1. Cloudflare Worker streams tokens back to Flutter client as normal via SSE
2. When the LAST token arrives and the full message is complete, the worker 
   simultaneously:
   - Sends the final token/done signal to the Flutter client AS NORMAL
   - Includes a unique speech URL in the done payload e.g. { done: true, speechUrl: "/api/v1/speech/abc-uuid-123" }
   - Spawns a separate async task that calls Google TTS with the full message text
3. The Google TTS response is held in a Cloudflare KV store or in-memory 
   cache keyed by the unique UUID
4. Flutter client sees the speechUrl in the done payload and immediately 
   opens a GET request to that endpoint
5. The Worker endpoint waits until Google TTS audio is ready, streams it 
   back to Flutter, then deletes it from storage immediately after
6. Flutter plays the audio as soon as bytes start arriving using just_audio

## CLOUDFLARE WORKER CHANGES

### Environment/Secrets
- GOOGLE_TEXT_API_KEY is already set as a Cloudflare secret and .env as as well as run_dev.sh
- Add a KV namespace called SPEECH_CACHE bound in wrangler.toml

### SSE Stream Changes
When the Anthropic stream completes and the full message is assembled:
- Generate a UUID for this speech request e.g. using crypto.randomUUID()
- Send the final SSE event as normal but include the speechUrl:
  data: { "done": true, "speechUrl": "/api/speech/<uuid>", "content": "<full message>" }
- Immediately after (non-blocking, do not await), kick off the Google TTS 
  request and store result in KV:
```javascript
  // Non-blocking - do not await this
  handleTTS(fullMessageText, uuid, env);

### Use these models based on language
const VOICES = {
  en: { languageCode: 'en-US', name: 'en-US-Journey-F' },
  th: { languageCode: 'th-TH', name: 'th-TH-Neural2-C' },
  zh: { languageCode: 'cmn-CN', name: 'cmn-CN-Wavenet-D' }
};

const voice = VOICES[lang] || VOICES.en;```

### New handleTTS function
```javascript
async function handleTTS(text, uuid, env) {
  const response = await fetch(
    `https://texttospeech.googleapis.com/v1/text:synthesize?key=${env.GOOGLE_TEXT_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        input: { text },
        voice: { languageCode: 'en-US', name: 'en-US-Journey-F' },
        audioConfig: { audioEncoding: 'MP3', speakingRate: 1.1 }
      })
    }
  );
  const data = await response.json();
  // Store base64 audio in KV with 60 second TTL so it auto-expires
  await env.SPEECH_CACHE.put(uuid, data.audioContent, { expirationTtl: 60 });
}
```

### New Speech Endpoint GET /api/speech/:uuid
- Poll KV for the audio up to 10 seconds (try every 200ms)
- When found, decode base64 to binary
- Return as audio/mpeg with appropriate headers
- Delete from KV immediately after returning
- If not found after 10 seconds return 404 silently
```javascript
async function handleSpeechRequest(uuid, env) {
  const maxWait = 10000;
  const interval = 200;
  let elapsed = 0;

  while (elapsed < maxWait) {
    const audio = await env.SPEECH_CACHE.get(uuid);
    if (audio) {
      await env.SPEECH_CACHE.delete(uuid);
      const binary = Uint8Array.from(atob(audio), c => c.charCodeAt(0));
      return new Response(binary, {
        headers: {
          'Content-Type': 'audio/mpeg',
          'Content-Length': binary.length.toString(),
          'Cache-Control': 'no-store'
        }
      });
    }
    await new Promise(resolve => setTimeout(resolve, interval));
    elapsed += interval;
  }
  return new Response(null, { status: 404 });
}
```

### wrangler.toml changes
Add KV namespace binding:
```toml
[[kv_namespaces]]
binding = "SPEECH_CACHE"
id = "YOUR_KV_NAMESPACE_ID"
```
Create the KV namespace with:
  wrangler kv:namespace create SPEECH_CACHE
And paste the returned ID into wrangler.toml

## FLUTTER CLIENT CHANGES

### Dependencies to add to pubspec.yaml
- just_audio
- http (if not present)

### Mute State
- Add bool isMuted = false to the chat screen StatefulWidget
- Store in setState

### Mute Button
- Add a Stack widget wrapping the entire chat screen
- Position an IconButton in the top right corner with SafeArea padding:
  - Icon: volume_up when unmuted, volume_off when muted
  - On press: toggle isMuted, if muted call audioPlayer.stop()
  - Style: semi-transparent dark circular background so it's visible 
    over any background color

### SSE Stream Parser Changes
When parsing the SSE stream, detect the done event:
- Parse the JSON payload
- Extract content as the full final message
- Extract speechUrl from the payload
- Display the message in chat as normal
- If isMuted is false, call playSpeech(speechUrl)

### New playSpeech function
```dart
final AudioPlayer audioPlayer = AudioPlayer();

Future<void> playSpeech(String speechPath) async {
  if (isMuted) return;
  try {
    // NOTE: use dev URL when in dev mode
    final url = 'https://api.shedidthat.app/api/v1/speech/$speechPath';
    await audioPlayer.setUrl(url);
    await audioPlayer.play();
  } catch (e) {
    // Silent fail - never block UI
  }
}
```

### Language Support
Pass the correct voice based on current app locale when calling handleTTS.
Add a language parameter to the SSE request body so the Worker knows 
which voice to use:
- English: languageCode "en-US", name "en-US-Journey-F"
- Thai: languageCode "th-TH", name "th-TH-Neural2-C"
- Chinese: languageCode "cmn-CN", name "cmn-CN-Wavenet-A"

### Mute Button Widget
```dart
Positioned(
  top: MediaQuery.of(context).padding.top + 8,
  right: 16,
  child: CFloatingActionButton(
                        onPressed: _isLoading ? null : _startNewConversation,
                        backgroundColor: _isLoading
                            ? AppColors.buttonSecondary
                            : AppColors.accent,
                        child: Icon(
        isMuted ? Icons.volume_off : Icons.volume_up,
        color: Colors.white,
      ),
      onPressed: () {
        setState(() => isMuted = !isMuted);
        if (isMuted) audioPlayer.stop();
      },
    ),
  ),
),
```

### Cleanup
- Call audioPlayer.dispose() in the widget's dispose() method

## IMPORTANT NOTES
- The TTS request is non-blocking — never await it inside the SSE handler
- The Flutter client should never show any error if TTS fails
- The KV TTL of 60 seconds means audio auto-expires even if Flutter never 
  fetches it, preventing any memory buildup
- Audio should begin playing as soon as just_audio receives the response 
  headers, not waiting for full download
- The mute button should work instantly — stopping mid-playback immediately

Please show all modified files in full.