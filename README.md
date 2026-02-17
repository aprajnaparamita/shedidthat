# She Absolutely Just Did That 🌈

### The post-sex debrief chatbot for lesbian and queer women.

> *"She may have left but we're still here, horizontal, ready to debrief."*

---

## What Is This

You know that thing where something incredible happens and you immediately need to tell someone? Like, you grab your phone before you've even caught your breath, because the experience is too good to just *sit* with alone?

That's this app.

**She Absolutely Just Did That** is a chatbot called Jess. Jess is your loudest, warmest, most obsessed best friend — the one who picks up on the first ring, immediately says *"I KNEW IT tell me everything"*, and genuinely wants to hear every single detail. She asks exactly the right follow-up questions. She validates you constantly. She loses her mind at the good parts.

She's an AI. She's always available. She never gets tired of hearing about it.

You had a great time. Jess wants to know. That's the whole app.

---

## How It Works

1. Open the app
2. Jess says something like *"You're glowing through the screen. Start from the beginning."*
3. You tell her everything
4. She asks follow-up questions like a best friend, not a survey
5. You eventually land on an official rating (1-10, for the record)
6. You feel thoroughly heard and validated
7. Close the app and go get a snack

---

## The Voice Feature

Because sometimes you're too horizontal to type.

Hold the microphone button and just talk. Jess will talk back. It's like a phone call with your best friend except your best friend is an AI and she never has to go pick up her kid.

You can turn voice on and off with the speaker icon in the top right. When it's off, Jess stays text-only. When it's on, she reads her replies out loud. Tap anywhere on the "Jess is talking..." indicator if you want to skip ahead. She'll understand.

---

## Your Privacy, For Real

**We do not save your conversations. Not on a server. Not in a database. Not anywhere except your own phone.**

Every debrief lives locally on your device and nowhere else. We don't know what you said. We can't read it. We couldn't sell it if we wanted to (we don't want to). When you delete a conversation, it's gone. When you delete the app, everything goes with it.

The only thing that touches our server is the message you're currently sending, which gets forwarded to the AI model and then immediately forgotten. We are not in the business of storing the intimate details of your sex life. That would be weird. We're not doing that.

Your phone. Your conversations. Nobody else's business.

---

## What Jess Is Not

- Jess is **not** a hookup app. She doesn't know anyone. She can't introduce you to people. She's an AI.
- Jess is **not** a therapist. If you need one of those, she'll probably gently suggest it and then ask you about your ex anyway.
- Jess is **not** going to ghost you. She's always here. This is her whole thing.
- Jess is **not** going to judge you. Not once. Not even a little.

---

## What Jess Is

Loud. Warm. Extremely invested. A little chaotic. Gay-culture-fluent in a way that feels like she's been paying attention. The friend who says *"SHE KNEW THE PLAYLIST?? That was premeditated. That is not an accident."*

She's your best friend at 11pm who you can tell everything to. Except she's an AI. And she will never, ever get tired of hearing about it.

---

## The Tech (For The Nerds)

- Flutter app — iOS and Android
- Tiny Express.js backend on Fly.io (scales to zero, costs almost nothing)
- Claude Haiku AI model (fast, cheap, plenty smart for this)
- Google Cloud Text-to-Speech (the voice feature, free tier covers a lot)
- Device speech-to-text (your phone's built-in, completely free)
- All conversations stored locally via SharedPreferences — never leaves your device

Running this app costs roughly $2 per 10,000 conversations in AI API costs. It is not a business. It is a bit.

---

## Frequently Asked Questions

**Is this a joke?**
It started as one. Then we built it. Now it works. The best things happen this way.

**Why does Jess use so many capital letters?**
Because she's EXCITED. She's been waiting for this call.

**Can I use this if I'm not a lesbian?**
Jess doesn't check. The vibe is universal. If you had a great time and need to tell someone, Jess is here.

**Does Jess remember our past conversations?**
Within a single conversation, yes — she remembers everything you've told her. Between separate conversations, no — each debrief starts fresh. Jess is like that friend who is fully present when you're talking but has the memory of a golden retriever otherwise.

**Will my conversations be used to train AI?**
No. They're on your phone. Nobody has them. See the privacy section above.

**What if it wasn't that good?**
Jess will help you figure that out too. Gently. With good questions. She's not just a hype machine — she's a reality check when you need one.

**Is Sappho proud of this?**
Genuinely yes.

---

## Contributing

Found a bug? Jess said something weird? Open an issue.

Want to improve Jess's personality? The entire character lives in `backend/persona.md`. It's a markdown file. Edit it. She'll be different immediately. This is genuinely the most important file in the codebase.

---

## License

MIT. Do what you want with it. If you make something great, tell us. Jess would want to know.

---

*Built with love, questionable judgment, and the firm belief that Sappho would have absolutely wanted this.*
