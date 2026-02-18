# Deployment Guide for Fly.io

This guide provides step-by-step instructions to deploy the "She Absolutely Just Did That" application (backend and frontend) to [Fly.io](https://fly.io/).

## Prerequisites

1.  **Install `flyctl`**: If you haven't already, install the Fly.io command-line tool.
    ```bash
    # For macOS
    brew install flyctl
    # For other systems, follow the official guide:
    # https://fly.io/docs/hands-on/install-flyctl/
    ```

2.  **Sign Up & Log In**: Create a Fly.io account and log in via the CLI.
    ```bash
    fly auth signup
    fly auth login
    ```

3.  **Fix Flutter SDK Permissions**: Your local Flutter installation has a permission issue. Before you can build the web app for deployment, you must fix this. Run the following command to grant your user account ownership of the Flutter SDK directory. You will be prompted for your password.
    ```bash
    sudo chown -R $(whoami) /Users/dara/dev/flutter
    ```
    After running this, run `flutter doctor` to confirm it works without permission errors.

---

## Part 1: Deploying the Backend (Node.js)

The backend is a Node.js application that connects to MongoDB.

### Step 1: Create a Dockerfile

In the `/Users/dara/dev/shedidthat/backend` directory, create a file named `Dockerfile` with the following content:

```dockerfile
# Use an official Node.js runtime as a parent image
FROM node:18-alpine

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install any needed packages
RUN npm install

# Copy the rest of the backend source code
COPY . .

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Define the command to run your app
CMD [ "node", "server.js" ]
```

### Step 2: Launch the App on Fly.io

Navigate to the backend directory and run `fly launch`.

```bash
cd /Users/dara/dev/shedidthat/backend
fly launch
```

This command will:
*   Scan your source code and detect the Node.js application.
*   Automatically create a `fly.toml` file to configure the deployment.
*   Ask you to choose an app name (e.g., `shedidthat-backend`).
*   Ask you to choose a region.
*   **IMPORTANT**: It will ask if you want to deploy now. **Select No**. We need to set secrets first.

### Step 3: Set Secrets

Your backend requires two secret environment variables: the MongoDB connection string and the application secret. Set them using the `fly secrets set` command.

```bash
# Replace <YOUR_BACKEND_APP_NAME> with the name you chose above.
# Replace <YOUR_MONGODB_URI> with your actual MongoDB Atlas connection string.
fly secrets set -a <YOUR_BACKEND_APP_NAME> MONGODB_URI="<YOUR_MONGODB_URI>"

# Replace <YOUR_APP_SECRET> with the secret key you use for authentication.
fly secrets set -a <YOUR_BACKEND_APP_NAME> APP_SECRET="<YOUR_APP_SECRET>"
```

### Step 4: Deploy the Backend

Now you can deploy the backend.

```bash
fly deploy
```

After the deployment is complete, take note of the app's hostname (e.g., `shedidthat-backend.fly.dev`). You will need this for the frontend.

---

## Part 2: Deploying the Frontend (Flutter Web)

The frontend is a Flutter web application that will be served by an Nginx web server.

### Step 1: Create Nginx Configuration

In the `/Users/dara/dev/shedidthat/frontend` directory, create a file named `nginx.conf` with the following content. This ensures that your single-page application works correctly with browser routing.

```nginx
server {
    listen 80;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Step 2: Create a Dockerfile

In the `/Users/dara/dev/shedidthat/frontend` directory, create a file named `Dockerfile` with the following content. This is a multi-stage Dockerfile that first builds the Flutter app and then serves the output with Nginx.

```dockerfile
# Stage 1: Build the Flutter web app
FROM cirrusci/flutter:latest as builder

WORKDIR /app

# Copy the frontend project files
COPY . .

# Get Flutter dependencies
RUN flutter pub get

# Define a build argument for the API URL
ARG API_URL

# Build the Flutter web app, passing the API URL as a compile-time variable
# This allows the app to know where the backend is located.
RUN flutter build web --dart-define=API_URL=${API_URL}

# Stage 2: Serve the built web app with Nginx
FROM nginx:stable-alpine

# Copy the built web app from the builder stage to the Nginx server directory
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy the custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

### Step 3: Launch the App on Fly.io

Navigate to the frontend directory and run `fly launch`.

```bash
cd /Users/dara/dev/shedidthat/frontend
fly launch
```

This will:
*   Detect the `Dockerfile`.
*   Create a `fly.toml` file.
*   Ask you to choose an app name (e.g., `shedidthat-frontend`).
*   Ask you to choose a region.
*   **IMPORTANT**: It will ask if you want to deploy now. **Select No**. We need to provide the backend URL.

### Step 4: Deploy the Frontend

Now, deploy the frontend. You must provide the backend's URL as a build argument so the frontend knows where to send API requests.

```bash
# Replace <YOUR_BACKEND_HOSTNAME> with the hostname from the backend deployment
# (e.g., https://shedidthat-backend.fly.dev)
fly deploy --build-arg API_URL=<YOUR_BACKEND_HOSTNAME>
```

After this command completes, your application will be live! You can visit the frontend's hostname (e.g., `shedidthat-frontend.fly.dev`) in your browser.
