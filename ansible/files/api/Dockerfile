# Base image for Node.js
FROM node:18-alpine

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
