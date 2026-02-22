# Deploying to Cloudflare Pages & Workers

This guide will walk you through deploying your Flutter frontend and Hono backend to the Cloudflare network.

- **Frontend (Flutter)** will be deployed to **Cloudflare Pages** at `shedidthat.app`.
- **Backend (Hono)** will be deployed to **Cloudflare Workers** at `app.shedidthat.app`.

---

## Part 1: Backend Deployment (Cloudflare Workers)

Your backend code in the `/backend` directory is already configured for Cloudflare Workers using `wrangler.toml`.

### Step 1: Install and Login to Wrangler

If you haven't already, install the Cloudflare CLI, Wrangler, and log in to your Cloudflare account.

```bash
npm install -g wrangler
wrangler login
```

### Step 2: Create a KV Namespace

Your worker uses Cloudflare KV to store device registrations. You need to create a KV namespace in your Cloudflare dashboard.

```bash
# This command creates a new KV namespace named 'DEVICE_KV'
wrangler kv namespace create "DEVICE_KV"
```

This command will output something like this:

```
✨ Success! 
Add the following to your wrangler.toml to bind to your new namespace:
[[kv_namespaces]]
binding = "DEVICE_KV"
id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Action:** Copy the `id` value.

### Step 3: Update `wrangler.toml`

Open `/backend/wrangler.toml` and paste the `id` you just copied into the `id` field for the `DEVICE_KV` binding. It should look like this:

```toml
[[kv_namespaces]]
binding = "DEVICE_KV"
id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # ← Paste your ID here
```

### Step 4: Set Production Secrets

Your worker needs three secrets to run in production. Set them using the following commands. Replace the placeholder values with your actual secrets. GOOGLE_TEXT_API_KEY is for Google's Cloud Text-To-Speech

```bash
# Run these commands from the /backend directory
wrangler secret put APP_SECRET
# (You will be prompted to enter the secret value)

wrangler secret put ANTHROPIC_API_KEY
# (You will be prompted to enter the secret value)

wrangler kv namespace create SPEECH_CACHE
wrangler secret put GOOGLE_TEXT_API_KEY
# (You will be prompted to enter the secret value)

```

### Step 5: Deploy!

Now you are ready to deploy the backend.

```bash
# Run this command from the /backend directory
wrangler deploy
```

After a successful deployment, your API will be live at a `*.workers.dev` URL. The final step is to add your custom domain.

### Step 6: Add Custom Domain (`app.shedidthat.app`)

1.  Go to your Cloudflare Dashboard.
2.  Select your domain (`shedidthat.app`).
3.  Go to the **Workers & Pages** section.
4.  Find your `shedidthat-backend` worker and click on it.
5.  Go to the **Triggers** tab.
6.  Click **Add Custom Domain** and enter `app.shedidthat.app`.

---

## Part 2: Frontend Deployment (Cloudflare Pages)

Your Flutter app will be deployed to Cloudflare Pages, which is optimized for hosting static sites.

### Step 1: Create a New Pages Project

1.  Go to your Cloudflare Dashboard.
2.  Go to **Workers & Pages** and select the **Pages** tab.
3.  Click **Create a new project** and connect it to your GitHub repository.

### Step 2: Configure Build Settings

When setting up the project, use the following configuration:

- **Framework preset**: `Flutter`
- **Build command**: `flutter build web --release --dart-define-from-file=.env`
- **Build output directory**: `/build/web`
- **Root directory**: `frontend`

### Step 3: Set Environment Variables

In the project settings under **Environment Variables**, you must add your `APP_SECRET` so the build command can access it.

- **Variable name**: `APP_SECRET`
- **Value**: `Your actual secret value`

### Step 4: Deploy!

Save the configuration and let Cloudflare build and deploy your site. It will be available at a `*.pages.dev` URL first.

### Step 5: Add Custom Domain (`shedidthat.app`)

1.  In your new Pages project dashboard, go to the **Custom domains** tab.
2.  Enter `shedidthat.app` and follow the instructions to set it as the primary domain.

Once both parts are deployed, your app will be fully live. The Flutter app is already configured to point to `https://api.shedidthat.app` in release mode, so it will automatically connect to your production backend.
