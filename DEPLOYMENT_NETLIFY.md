# Deployment Guide for Netlify

This guide provides step-by-step instructions to deploy the "She Absolutely Just Did That" application to Netlify. We will deploy the backend and frontend as two separate Netlify sites.

---

## Part 1: Deploying the Backend (Node.js)

Netlify runs backend code using **Netlify Functions**, which are serverless functions. We need to adapt the Express.js server to be compatible with this model. We'll use the `serverless-http` package to wrap our existing Express app.

### Step 1: Update Backend Code

1.  **Install `serverless-http`**:
    Navigate to your backend directory in your terminal and run the following command:
    ```bash
    cd /Users/dara/dev/shedidthat/backend
    npm install serverless-http
    ```

2.  **Create a Function Entry Point**:
    Create a new folder named `functions` inside your `backend` directory. Inside this new `functions` folder, create a file named `api.js`.
    ```
    backend/
    ├── functions/
    │   └── api.js
    ├── node_modules/
    ├── server.js
    ├── package.json
    └── ...
    ```
    Add the following code to `backend/functions/api.js`. This file will be the entry point for the Netlify Function.

    ```javascript
    const serverless = require('serverless-http');
    const { app } = require('../server'); // Import the Express app

    // Wrap the app for serverless execution
    module.exports.handler = serverless(app);
    ```

3.  **Modify `server.js` to Export the App**:
    Your main `server.js` file needs to export the `app` instance so that `functions/api.js` can import it. Make the following changes to `/Users/dara/dev/shedidthat/backend/server.js`:

    *   **Find this line at the bottom of the file:**
        ```javascript
        app.listen(port, () => {
          console.log(`Server listening on port ${port}`);
        });
        ```
    *   **Add the following export statement right below it:**
        ```javascript
        module.exports = { app };
        ```

### Step 2: Create Netlify Configuration File

Create a file named `netlify.toml` in the root of your `backend` directory (`/Users/dara/dev/shedidthat/backend/netlify.toml`). This file tells Netlify how to handle your project.

Add the following content to it:

```toml
[build]
  # This tells Netlify where to find our serverless function.
  functions = "functions/"

# This rule makes our function accessible at a clean URL.
# Requests to /api/* will be routed to our api.js function.
[[redirects]]
  from = "/api/*"
  to = "/.netlify/functions/api/:splat"
  status = 200
```

### Step 3: Deploy Backend to Netlify

1.  Push your changes (the new `functions/api.js` file, `netlify.toml`, and modified `server.js` and `package.json`) to your GitHub repository.
2.  Go to your Netlify dashboard and click "Add new site" -> "Import an existing project".
3.  Connect to your Git provider and select the repository.
4.  In the build settings, set the **Base directory** to `backend`. Netlify should automatically detect that you have no build command and that your functions directory is `functions`.
5.  Click "Deploy site".
6.  Once the site is created, go to "Site settings" -> "Build & deploy" -> "Environment".
7.  Add your secret environment variables:
    *   `MONGODB_URI`: Your MongoDB Atlas connection string.
    *   `APP_SECRET`: Your application secret key.
8.  Trigger a new deploy to apply the environment variables. After it's live, your backend API will be available at `https://<your-backend-site-name>.netlify.app/api`.

---

## Part 2: Deploying the Frontend (Flutter Web)

Netlify is perfect for hosting static sites like a Flutter web app.

### Step 1: Create Netlify Configuration File

Create a file named `netlify.toml` in the root of your `frontend` directory (`/Users/dara/dev/shedidthat/frontend/netlify.toml`).

Add the following content to it. This tells Netlify how to build your Flutter app and configures it as a single-page application (SPA).

```toml
[build]
  # This is the command to build the Flutter web app.
  # The $API_URL is an environment variable we will set in Netlify's UI.
  command = "flutter build web --dart-define=API_URL=$API_URL"

  # This is the directory that contains the built site.
  publish = "build/web"

  # The Flutter version to use.
  [build.environment]
    FLUTTER_VERSION = "3.19.0" # Or your specific Flutter version

# This redirect rule is essential for a single-page application (SPA).
# It ensures that all routes are handled by your app's index.html file.
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### Step 2: Deploy Frontend to Netlify

1.  Push the new `netlify.toml` file in your `frontend` directory to your GitHub repository.
2.  In Netlify, create another new site ("Add new site" -> "Import an existing project").
3.  Select the same repository again.
4.  In the build settings, this time set the **Base directory** to `frontend`.
5.  Netlify will read your `netlify.toml` and configure the build settings automatically.
6.  Before deploying, click "Advanced build settings" and add a new environment variable:
    *   `API_URL`: Set this to the full URL of your deployed backend (e.g., `https://<your-backend-site-name>.netlify.app/api`).
7.  Click "Deploy site".

Once the build is complete, your Flutter application will be live and connected to your backend running on Netlify Functions.
