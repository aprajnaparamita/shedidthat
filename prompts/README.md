# She Absolutely Just Did That 🌈
## Build Prompts — README

These prompts are designed to be pasted directly into a local Claude instance (or any Claude conversation) to build the app piece by piece. Each prompt is fully self-contained — Claude doesn't need to have seen this conversation to understand what to build.

---

## Recommended Build Order

### 01_BACKEND_PROMPT.md
**Run first.** Builds the complete Express.js backend including:
- server.js with all security layers
- persona.md (Jess's full personality)
- package.json
- fly.toml (Fly.io deployment config)
- Deployment commands

### 02_FLUTTER_PROMPT.md
**Run second.** Builds the complete Flutter app including:
- All screens (Home, Chat)
- All services (API, Storage, Device)
- Message model
- pubspec.yaml

### 03_TUNE_JESS_PROMPT.md
**Run any time.** Paste your current persona.md and describe what's not working. Claude will rewrite it. This is the most important ongoing prompt — Jess's personality IS the product.

### 04_SECURITY_PROMPT.md
**Run after you have a working server.js.** Paste your current server.js and Claude will audit and harden all security layers.

### 05_APP_STORE_PROMPT.md
**Run when ready to launch.** Generates all App Store and Google Play copy, age rating guidance, and social media launch content.

### 06_UI_DESIGN_PROMPT.md
**Run after the basic app is working.** Builds the complete Flutter design system, custom widgets, animations, and theming.

---

## Key Architecture Reminders

- **Backend:** Express.js on Fly.io, scales to zero ($0 when idle)
- **AI Model:** claude-haiku-4-5-20251001 (cheapest, ~$2 per 10,000 conversations)
- **Storage:** Local device only via SharedPreferences — no database ever
- **Memory:** Full conversation history sent on every API call — Claude's context window IS the memory
- **Security:** App secret header + device token + rate limiting + spend limits in Anthropic dashboard

## First Thing To Do After Deployment

Set a monthly spend limit in the Anthropic console:
https://console.anthropic.com → Billing → Usage limits

Set it to $20/month to start. This is your financial safety net.

---

## App Identity

- **Name:** She Absolutely Just Did That
- **Domain:** sheabsolutelyjustdidthat.app (or shejustknew.app)
- **Tagline:** "She may have left but we're still here, horizontal, ready to debrief."
- **Chatbot character:** Jess
- **Target audience:** Lesbian and queer women 18-35
- **Vibe:** Texting your wildest best friend at 11pm

---

*Sappho would have wanted this.*
