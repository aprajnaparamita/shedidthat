Great work. I want to play Jess's returned audio after the request comes back. The Node.js backend  is deployed as a Cloudflare Worker. I want to add 
a /api/jess/speak endpoint that accepts a `text` query parameter and a 
`lang` query parameter (en, th, zh) and returns an MP3 audio file.

I cannot use edge-tts directly since Cloudflare Workers can't run Python 
or shell commands. Instead, use the Microsoft Edge TTS REST API directly 
via fetch calls to Microsoft's Cognitive Services.

The voices to use are:
- English: en-US-JennyNeural
- Thai: th-TH-PremwadeeNeural  
- Chinese: zh-CN-XiaoxiaoNeural

Please:
1. Implement the endpoint in my Cloudflare Worker using the Microsoft 
   Speech Synthesis REST API (api.cognitive.microsoft.com) with SSML 
   request format
2. The endpoint should accept GET requests with `text` and `lang` query 
   params
3. Return the audio as audio/mpeg with appropriate headers
4. Handle CORS so my Flutter app can call it
5. Store the Microsoft Speech API key as a Cloudflare Worker secret 
   called MICROSOFT_SPEECH_KEY and region as MICROSOFT_SPEECH_REGION
6. Add error handling for missing text, unsupported languages, and API 
   failures

Note: Microsoft Azure Cognitive Services Speech API has a free tier of 
500,000 characters per month which should be sufficient. Please also 
give me the steps to set up the free Azure account and get the API key, 
and how to add it as a Cloudflare Worker secret via wrangler CLI.
