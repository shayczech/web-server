# ------------------------------------------------------------------------------
# Stats API: multi-stage build. Builder installs deps; final image is distroless.
# ------------------------------------------------------------------------------

FROM node:22-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm install --production
RUN npm audit fix || true

ARG BUILD_TIMESTAMP=0
RUN echo "Build at ${BUILD_TIMESTAMP}"

COPY . .

FROM gcr.io/distroless/nodejs22-debian12
COPY --from=builder /app /app
WORKDIR /app

EXPOSE 3000
CMD ["server.js"]
