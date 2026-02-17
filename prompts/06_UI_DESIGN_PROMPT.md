# Prompt 6 — UI Design & Theming

Paste this into your local Claude to get a complete Flutter UI design system.

---

I need a complete UI design system for a Flutter app called "She Absolutely Just Did That." It is a post-sex debrief chatbot for lesbian and queer women. The chatbot character is Jess — a loud, warm best friend.

BRAND PERSONALITY:
- Fun, warm, slightly chaotic
- Feels like texting your wildest best friend
- NOT clinical, NOT corporate, NOT a hookup app
- Queer joy energy — celebratory, affirming, a little unhinged

COLOR PALETTE (already decided):
- Primary: Deep purple #4A0E5C
- Accent: Hot pink #E91E8C
- Background: Off-white or very light lavender
- Jess bubble: Light grey #F0F0F0
- User bubble: Gradient from #4A0E5C to #E91E8C or solid pink

Please create the following Flutter files:

1. lib/theme/app_theme.dart
   - Complete MaterialApp ThemeData
   - Both light theme (primary use) and dark theme
   - Custom text styles for: heading, body, bubble text, timestamp, empty state
   - Button styles
   - Input decoration theme for the chat text field
   - AppBar theme
   - BottomNavigationBar theme if needed

2. lib/theme/app_colors.dart
   - All color constants
   - Gradient definitions

3. lib/widgets/chat_bubble.dart
   - Reusable widget for both user and Jess messages
   - User: right-aligned, pink/purple
   - Jess: left-aligned, grey, with a small circular "J" avatar in purple
   - Rounded corners, proper padding
   - Timestamp shown subtly below
   - Smooth appear animation when a new message arrives

4. lib/widgets/jess_typing_indicator.dart
   - Animated "Jess is typing..." indicator
   - Three bouncing dots in the Jess bubble style
   - Shows while waiting for API response

5. lib/widgets/conversation_card.dart
   - Card for the home screen conversation list
   - Shows: preview text, relative time ("2 hours ago", "just now", "yesterday")
   - Subtle purple left border or accent
   - Swipe-to-delete ready (wrap in Dismissible)
   - Tap ripple effect

6. lib/widgets/empty_state.dart
   - Fun empty state for when there are no conversations yet
   - Include a large emoji or simple illustration concept
   - Headline: "No debriefs yet."
   - Subtext: "What are you waiting for?"
   - A big pink "Start Debriefing" button

After writing all files, provide a brief style guide: fonts used, spacing system, and any design decisions worth noting.
