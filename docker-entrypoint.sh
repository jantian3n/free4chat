#!/usr/bin/env bash
set -e

# Defaults for single-VPS self-hosted deployment
export PORT="${PORT:-3000}"
export IP="${IP:-0.0.0.0}"
export PERSIST_DIR="${PERSIST_DIR:-/data}"
export TURNSTILE_DISABLED="${TURNSTILE_DISABLED:-true}"
export ALLOW_ANY_ORIGIN="${ALLOW_ANY_ORIGIN:-true}"
export ALLOW_ANY_HOST="${ALLOW_ANY_HOST:-true}"
export ROOM_APPS_ENABLED="${ROOM_APPS_ENABLED:-true}"

# If SFU_APP_ID is not configured, automatically enable simulated SFU mode
# so text chat, agent tasks, MCP, and collaboration work without Cloudflare Calls
if [ -z "$SFU_APP_ID" ]; then
  export SFU_MOCK_ENABLED="${SFU_MOCK_ENABLED:-true}"
else
  export SFU_MOCK_ENABLED="${SFU_MOCK_ENABLED:-false}"
fi

mkdir -p "$PERSIST_DIR"

echo "=================================================="
echo " Free4Chat - Single VPS Self-Hosted Server"
echo "=================================================="
echo " Listening on:       http://${IP}:${PORT}"
echo " Data persistence:   ${PERSIST_DIR}"
echo " Turnstile disabled: ${TURNSTILE_DISABLED}"
echo " Allow any origin:   ${ALLOW_ANY_ORIGIN}"
echo " Allow any host:     ${ALLOW_ANY_HOST}"
if [ -n "$SFU_APP_ID" ]; then
  echo " WebRTC Media SFU:   Cloudflare Realtime (App: ${SFU_APP_ID})"
else
  echo " WebRTC Media SFU:   Simulated / Offline Mode (Chat & Agents active)"
fi
if [ -n "$APP_URL" ]; then
  echo " Public App URL:     ${APP_URL}"
fi
echo "=================================================="

# Assemble wrangler variables to inject into Worker runtime
VARS=(
  --var "TURNSTILE_DISABLED:${TURNSTILE_DISABLED}"
  --var "ALLOW_ANY_ORIGIN:${ALLOW_ANY_ORIGIN}"
  --var "ALLOW_ANY_HOST:${ALLOW_ANY_HOST}"
  --var "ROOM_APPS_ENABLED:${ROOM_APPS_ENABLED}"
)

if [ -n "$SFU_APP_ID" ]; then
  VARS+=(--var "SFU_APP_ID:${SFU_APP_ID}")
fi

if [ -n "$SFU_APP_SECRET" ]; then
  VARS+=(--var "SFU_APP_SECRET:${SFU_APP_SECRET}")
fi

if [ -n "$SFU_MOCK_ENABLED" ]; then
  VARS+=(--var "SFU_MOCK_ENABLED:${SFU_MOCK_ENABLED}")
fi

if [ -n "$APP_URL" ]; then
  VARS+=(--var "APP_URL:${APP_URL}")
fi

if [ -n "$ALLOWED_ORIGINS" ]; then
  VARS+=(--var "ALLOWED_ORIGINS:${ALLOWED_ORIGINS}")
fi

if [ -n "$ALLOWED_HOSTNAMES" ]; then
  VARS+=(--var "ALLOWED_HOSTNAMES:${ALLOWED_HOSTNAMES}")
fi

export CI=true

exec npx wrangler dev \
  --ip "$IP" \
  --port "$PORT" \
  --persist-to "$PERSIST_DIR" \
  --show-interactive-dev-session false \
  "${VARS[@]}"
