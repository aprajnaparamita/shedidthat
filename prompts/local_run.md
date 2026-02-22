I need you to implement a "Run Locally" mode for this Flutter iOS app. Here is exactly what needs to be done:

**1. Splash Screen Toggle**

Add a toggle button to the splash screen to the right of the "Your Privacy Matters" text. It should switch between two states: "Run Locally" and "Use shedidthat.app". This toggle should persist to local storage using the same mechanism currently used for chats and the device key.

**2. Get Started Button Logic**

When the user has selected "Run Locally" and taps "Get Started", check local storage for the presence of both `DEEPSEEK_API_TOKEN` and `GOOGLE_TEXT_API_KEY`. If either is missing, navigate to the token setup screen described below. If both are present and validated, proceed normally.

**3. Token Setup Screen (get_token)**

Create a new screen that explains the user must sign up for two services to use local mode. It should contain:

- A brief explanation of why these keys are needed
- For each key: a clickable button linking to the relevant service console, a text input field for pasting the key, a format validation check on the input, and a "Test" button that validates the key against the actual API and shows a checkmark on success
- A "Get Started" button that is disabled until both keys have been successfully tested and validated
- On success, save both keys to local storage using the same storage mechanism as the device key and chats

The two services are DeepSeek (DEEPSEEK_API_TOKEN) and Google Text API (GOOGLE_TEXT_API_KEY). Please look up the correct console URLs and expected token formats for each by searching the codebase for any existing references first.

**4. Sentry Disabling**

Add Sentry support to the Flutter app frontend/ using `SENTRY_DSN` env variable in ONLY the Flutter frontend Wrap every Sentry initialization, event capture, and breadcrumb call in a conditional that checks whether the app is running in local mode. If local mode is active, all Sentry code should be skipped entirely — no initialization, no error reporting. Do not remove the code, just gate it.

**5. Storage**

Look at how the device key and chat history are currently stored and use the exact same mechanism for storing the toggle state, DEEPSEEK_API_TOKEN, and GOOGLE_TEXT_API_KEY.

**6. Internationalization**

All UI must be translated to the supported languages of English
(default), Thai and Mandarin Chinese

**7. Server backend**
The current server in backend/

**General instructions:**

- Before writing any code, read the existing codebase thoroughly to understand current storage patterns, navigation patterns, and screen structure
- Match the existing code style and UI conventions exactly
- Do not introduce any new dependencies without checking if an existing one already covers the need
- After implementing, list every file you changed and why

**Server Backend**

I need you to rewrite the existing Cloudflare Workers backend (`backend/server.js`) as a Dart implementation that runs locally within the Flutter application using the `shelf` package for HTTP routing. The two implementations must be functionally identical and verified by a shared test suite.

**1. Understand the existing implementation first**

Before writing any code, thoroughly read `backend/server.js` and understand:
- Every route it exposes and what each one does
- How it handles authentication and API key usage
- How it calls DeepSeek and Google Text APIs, including request shapes, headers, and response handling
- How it handles errors and what it returns in each error case
- Any middleware, CORS handling, or request validation
- Any environment variables it reads and how they are used
- Any Cloudflare-specific APIs or bindings it uses (KV, D1, etc.) and what the equivalent behavior should be in local mode

Document your findings as a comment block at the top of the new Dart file before writing any implementation code.

**2. Create the local Dart server**

Create a new file at `frontend/lib/local_server/local_server.dart`. Using the `shelf` and `shelf_router` packages, implement every route from `backend/server.js` with identical behavior. Specific requirements:

- Read `DEEPSEEK_API_TOKEN` and `GOOGLE_TEXT_API_KEY` from the same local storage location used by the token setup screen, not from environment variables
- Any Cloudflare-specific storage (KV, D1, etc.) should be replaced with the same local storage mechanism used elsewhere in the app
- CORS and error response shapes must match the original exactly so the frontend sees no difference
- The server should start on localhost on a fixed port. Choose a port that does not conflict with anything else in the project and define it as a constant
- The server should be startable and stoppable via a simple interface so the app lifecycle can manage it cleanly
- If any route in the original uses Sentry, gate those calls behind the same local mode conditional established in the previous task

**3. Integrate with the app**

- When the app is in "Run Locally" mode, start the local Dart server when the app launches and stop it when the app is terminated
- Any place in the Flutter code that constructs the base URL for API calls should look at a single variable which is normally the https://api.shedidthat.app but if in local mode points to the local server
- Do not hardcode the URL anywhere new — find the existing URL configuration pattern and extend it

**4. Write a shared test suite**

Create tests at `backend/test/server_parity_test.dart` and `frontend/test/server_parity_test.js` (or use Jest if the project already has a JS test setup). The two test files should be mirrors of each other and cover every route. For each route, tests should:

- Send identical requests to both the Node/Cloudflare implementation and the Dart implementation running locally
- Assert that response status codes match
- Assert that response body shapes match (same keys, same types)
- Assert that error cases return the same structure (bad input, missing auth, invalid tokens, upstream API failure simulated with a mock)
- Assert that any data written to storage is written correctly in both implementations

Use a shared JSON fixture file at `test/fixtures/server_test_cases.json` to define all request/response pairs so both test files draw from the same source of truth. This fixture file should be generated first before writing either test file.

**5. General instructions**

- Before writing any code, search the entire codebase for existing uses of `shelf`, `shelf_router`, and any existing local server setup to avoid duplicating work
- Match the existing Dart code style exactly
- Do not introduce dependencies beyond `shelf` and `shelf_router` without checking if something already in `pubspec.yaml` covers the need
- If any part of `backend/server.js` uses a Cloudflare-specific feature with no clean local equivalent, flag it explicitly with a TODO comment and implement the closest reasonable approximation
- After completing the implementation, produce a summary listing every route ported, every file created or modified, and any behavioral differences between the two implementations that could not be avoided
