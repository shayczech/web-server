# Stage 1: install deps and prepare app (npm only used here, not in final image)
FROM node:22-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm install --production
RUN npm audit fix || true

# Cache-bust so pipeline always gets latest server.js (security score, etc.)
ARG BUILD_TIMESTAMP=0
RUN echo "Build at ${BUILD_TIMESTAMP}"

COPY . .

# Stage 2: minimal runtime — no npm, no Alpine; only Node + your app
# Removes npm-bundled vulns (tar, glob, etc.) and Alpine/OpenSSL vulns
FROM gcr.io/distroless/nodejs22-debian12
COPY --from=builder /app /app
WORKDIR /app

EXPOSE 3000
CMD ["server.js"]
