# Base image for Node.js
FROM node:20-alpine

# This updates all OS packages in the image to their latest versions
RUN apk update && apk upgrade

# Set the working directory inside the container
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./
# Only install production dependencies
RUN npm install --production

# Attempt to fix other vulnerable NPM packages (will respect overrides)
RUN npm audit fix || true

# --- NEW: Explicitly install the fixed version of cross-spawn ---
# This forces the non-vulnerable version into the image layer
RUN npm install cross-spawn@7.0.5 --no-save

# Copy application source code
COPY . .

# Expose port (internal to the container)
EXPOSE 3000

# Command to run the application
CMD [ "node", "server.js" ]