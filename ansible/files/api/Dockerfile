# Base image for Node.js
FROM node:18-alpine

# --- NEW: Add this line to update packages and patch vulnerabilities ---
# This updates all OS packages in the image to their latest versions
RUN apk update && apk upgrade

# Set the working directory inside the container
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./
RUN npm install

# Copy application source code
COPY . .

# Expose port (internal to the container)
EXPOSE 3000

# Command to run the application
CMD [ "node", "server.js" ]
