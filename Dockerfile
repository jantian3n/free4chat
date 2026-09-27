# ==============================================================================
# Free4Chat Single VPS Container Build
# Multi-stage Dockerfile using Node 22 on Debian Bookworm Slim
# ==============================================================================

# Stage 1: Build Next.js & OpenNext Cloudflare Worker
FROM node:22-bookworm-slim AS builder

WORKDIR /build

# Install dependencies required for building
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy package descriptors first for Docker layer caching
COPY app/package.json app/yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy application source code
COPY app/ ./

# Disable Turnstile by default at build time for self-hosted VPS environments
ARG NEXT_PUBLIC_TURNSTILE_DISABLED=1
ENV NEXT_PUBLIC_TURNSTILE_DISABLED=1

# Compile Next.js Pages and bundle OpenNext Cloudflare worker (.open-next/worker.js)
RUN yarn cf-build

# ==============================================================================
# Stage 2: Production Runtime
# ==============================================================================
FROM node:22-bookworm-slim AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV CI=true

# Create data directory for persistent SQLite storage (Durable Objects & KV)
RUN mkdir -p /data

# Copy built application and required runtime dependencies from builder
COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/.open-next ./.open-next
COPY --from=builder /build/package.json ./package.json
COPY --from=builder /build/worker.ts ./worker.ts
COPY --from=builder /build/wrangler.jsonc ./wrangler.jsonc
COPY --from=builder /build/src ./src

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose standard application port
EXPOSE 3000

# Persist Durable Objects and KV storage
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
