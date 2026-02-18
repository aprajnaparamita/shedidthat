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
