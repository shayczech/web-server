# Base image for Node.js
# --- MODIFIED: Upgraded from 18 to 20 (current LTS) ---
FROM node:20-alpine

# This updates all OS packages in the image to their latest versions
RUN apk update && apk upgrade

# Set the working directory inside the container
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./
# This is a best practice to reduce the image size and attack surface.
RUN npm install --production

# --- Attempt to fix vulnerable NPM packages ---
RUN npm audit fix || true

# --- NEW: Explicitly update the package flagged by Trivy ---
# We force update cross-spawn to the known fixed version 7.0.5
RUN npm update cross-spawn@7.0.5

# Copy application source code
COPY . .

# Expose port (internal to the container)
EXPOSE 3000

# Command to run the application
CMD [ "node", "server.js" ]

