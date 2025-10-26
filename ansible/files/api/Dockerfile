# Base image for Node.js
FROM node:18-alpine

# --- NEW: Add this line to update packages and patch vulnerabilities ---
# This updates all OS packages in the image to their latest versions
RUN apk update && apk upgrade

# Set the working directory inside the container
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./

# This is a best practice to reduce the image size and attack surface.
RUN npm install --production

# This attempts to fix any known vulnerabilities in the node_modules
# We use '|| true' so it doesn't fail the build if it can't auto-fix
RUN npm audit fix || true

# Copy application source code
COPY . .

# Expose port (internal to the container)
EXPOSE 3000

# Command to run the application
CMD [ "node", "server.js" ]
