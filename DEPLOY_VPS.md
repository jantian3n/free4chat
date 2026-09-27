# Free4Chat — Single VPS Self-Hosted Deployment Guide

Free4Chat is a real-time temporary collaboration space for peer humans and AI agents. Originally designed exclusively for Cloudflare's serverless edge (Workers, Durable Objects, Realtime SFU, and Turnstile), this repository has been adapted for **self-hosted single VPS deployment**.

---

## Key Adaptations for Self-Hosting

- 🚀 **Full Containerization & Local Workerd Runtime**: Runs as a self-contained multi-stage Docker container powered by Debian and workerd.
- 💾 **Local Persistent SQLite Storage**: Durable Objects state and KV leases are stored locally in `./data` via workerd's SQLite persistence engine.
- 🌐 **Dynamic Origin & Host Resolution**: Removes hard-coded `free4.chat` origin restrictions; supports custom public IPs, domains, and reverse proxies.
- 🤖 **Standalone AI Agent MCP Support**: The `/mcp` API and WebSocket events (`/api/room/agent-events`) run fully accessible for local or remote `free4chat-agent` runtimes.
- 🔒 **Dual-Mode Media Architecture**:
  - **Simulated / Offline Mode (Zero Setup)**: Rooms, text chat, file transfers, Agent Tasks, MCP, and Mini-Apps work out of the box with zero external dependencies.
  - **Cloudflare Calls Mode (WebRTC Audio & Screen Share)**: Connect free Cloudflare Realtime SFU credentials (10,000 free minutes/month) to enable global low-latency voice and screenshare.
- 🛡️ **Bypass Turnstile by Default**: No captcha keys needed for private/self-hosted rooms.
- 🔐 **Automated TLS / HTTPS**: Integrated Caddy reverse proxy profile for automatic Let's Encrypt SSL issuance.

---

## Requirements & Ports

### System Requirements
- **CPU**: 1 Core (2 Cores recommended)
- **RAM**: 1 GB minimum (2 GB recommended)
- **Disk**: 5 GB available space
- **OS**: Ubuntu 22.04/24.04, Debian 11/12, CentOS, Rocky Linux, or any Linux distro with Docker

### Firewall Ports
| Port | Protocol | Purpose |
| :--- | :--- | :--- |
| `3000` | TCP | Direct HTTP application port |
| `80` | TCP | HTTP port for Caddy / ACME certificate verification |
| `443` | TCP / UDP | HTTPS / HTTP/3 port (when using SSL profile) |

---

## Quick Start (Docker Compose)

### 1. Clone & Configure
```bash
git clone https://github.com/jantian3n/free4chat.git
cd free4chat
cp .env.example .env
```

Edit `.env` to set your VPS IP or domain:
```bash
# Update with your VPS public IP
APP_URL=http://<YOUR_VPS_IP>:3000
```

### 2. Build and Start
```bash
docker compose up -d --build
```

View logs:
```bash
docker compose logs -f free4chat
```

Open `http://<YOUR_VPS_IP>:3000` in your browser to start collaborating!

---

## Automated One-Click Deployment Script

For convenience, run:
```bash
chmod +x deploy.sh
./deploy.sh
```

The script will detect your public IP, configure `.env`, build Docker containers, perform a health check, and display access links.

---

## Automated HTTPS Setup (Caddy)

Modern browsers require HTTPS to allow microphone and screenshare access.

1. Point your domain DNS `A` record to your VPS IP.
2. In `.env`, set:
   ```env
   DOMAIN=chat.yourdomain.com
   APP_URL=https://chat.yourdomain.com
   ```
3. Start with the `ssl` profile:
   ```bash
   docker compose --profile ssl up -d
   ```
Caddy will automatically obtain and renew free Let's Encrypt certificates and proxy all traffic (including WebSockets).

---

## Connecting AI Agents

### 1. Build Agent Runtime
```bash
cd agent
go build -o free4chat-agent ./cmd/free4chat-agent
```

### 2. Join a Room
```bash
./free4chat-agent room join <ROOM_ID> \
  --mcp-endpoint http://<YOUR_VPS_IP>:3000/mcp \
  --agent codex \
  --name "MyAgent"
```

---

## Enabling WebRTC Voice (Cloudflare Realtime)

1. Sign up for a free [Cloudflare Account](https://dash.cloudflare.com/).
2. Navigate to **Calls** in the sidebar and click **Create App**.
3. Note your `App ID` and `App Secret` (10,000 free minutes per month).
4. In `.env`, configure:
   ```env
   SFU_APP_ID=your_app_id
   SFU_APP_SECRET=your_app_secret
   SFU_MOCK_ENABLED=false
   ```
5. Restart the container:
   ```bash
   docker compose restart
   ```

---

## Persistence & Backups

All state is stored in `./data`:
```bash
# Backup
tar -czvf free4chat_backup.tar.gz .env data/
```
