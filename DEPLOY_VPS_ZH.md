# Free4Chat 单 VPS 自建部署指南 (Single VPS Self-Hosted Guide)

Free4Chat 是一个用于人类与 AI Agent 临时协作的实时沟通空间。原本官方版本深度依赖 Cloudflare 生态（Cloudflare Workers、Durable Objects、Cloudflare Realtime SFU 及 Turnstile）。

本项目已完成**单 VPS 自建部署适配**，实现以下核心能力：

- 🚀 **全功能容器化运行**：通过轻量多阶段 Docker 镜像，基于 Debian 与 workerd 引擎，无需任何 Cloudflare 基础设施即可在单台独立 Linux VPS 上自建运行。
- 💾 **本地 SQLite 数据持久化**：Durable Objects 状态与房间会话自动持久化存储于本地 `./data` 目录，容器重启数据不丢失。
- 🌐 **解除域名与 Origin 硬编码**：支持自定义公网 IP、自定义域名、动态 Origin 校验与 MCP Hostname 适配。
- 🤖 **AI Agent 100% 独立运作**：MCP 协议端点（`/mcp`）与 Agent 事件流（WebSocket）完全解耦，支持任何本地/远程 Agent 通过 `free4chat-agent` CLI 自由加入房间。
- 🔒 **可选离线模拟 / 云端 WebRTC 双模式**：
  - **默认离线模式**（无需 Cloudflare 账号）：房间建立、文字聊天、文件传输、Agent Tasks 任务协作、MCP 交互、Mini-App 完全自主可控。
  - **Cloudflare Calls 模式**（开启语音与屏幕共享）：配置免费的 Cloudflare SFU 凭据（每月 10,000 分钟免费额度），即可通过全球 Anycast 边缘获得超低延迟语音与屏幕共享。
- 🛡️ **免 Turnstile 验证**：默认禁用验证码限制，局域网与公网无感极速加入房间。
- 🔐 **自动 HTTPS 证书**：集成 Caddy 反向代理，填入域名即可自动申请并续订免费 Let's Encrypt / ZeroSSL 证书。

---

## 目录

1. [配置要求与网络端口](#1-配置要求与网络端口)
2. [部署方式一：Docker Compose 极速部署（推荐）](#2-部署方式一docker-compose-极速部署推荐)
3. [部署方式二：一键脚本自动化部署](#3-部署方式二一键脚本自动化部署)
4. [部署方式三：宿主机原生部署 (Node + Systemd)](#4-部署方式三宿主机原生部署-node--systemd)
5. [域名与 HTTPS 证书配置](#5-域名与-https-证书配置)
6. [接入与运行 AI Agent](#6-接入与运行-ai-agent)
7. [开启 WebRTC 语音与屏幕共享 (可选)](#7-开启-webrtc-语音与屏幕共享-可选)
8. [数据备份与目录结构](#8-数据备份与目录结构)
9. [常见问题解答 (FAQ)](#9-常见问题解答-faq)

---

## 1. 配置要求与网络端口

### 最低硬件要求
- **CPU**: 1 核 (推荐 2 核)
- **内存**: 1 GB RAM (推荐 2 GB RAM)
- **磁盘**: 至少 5 GB 可用空间
- **操作系统**: Ubuntu 22.04/24.04 LTS, Debian 11/12, CentOS 8/9 Stream, AlmaLinux, RockyLinux 等主流 Linux 发行版

### 需要开放的防火墙端口
| 端口号 | 协议 | 用途 |
| :--- | :--- | :--- |
| `3000` | TCP | 基础 HTTP 访问端口（直接部署模式） |
| `80` | TCP | HTTP 端口（使用 Caddy/Nginx 反代及 ACME 证书申请） |
| `443` | TCP / UDP | HTTPS / HTTP3 端口（域名 SSL 模式） |

---

## 2. 部署方式一：Docker Compose 极速部署（推荐）

这是最推荐、最稳健的部署方式，所有依赖均封装在容器中。

### 第一步：克隆代码仓库

```bash
git clone https://github.com/jantian3n/free4chat.git
cd free4chat
```

### 第二步：生成配置文件

复制模板生成 `.env` 文件：

```bash
cp .env.example .env
```

根据你的实际网络环境编辑 `.env`（默认配置已优化，可直接使用）：

```bash
nano .env
```

主要配置项说明：
```bash
# 你的 VPS 公网 IP 或域名
APP_URL=http://<你的VPS公网IP>:3000

# 保持默认即可免 Captcha 人机验证
TURNSTILE_DISABLED=true

# 保持默认即可零配置使用聊天与 Agent
SFU_MOCK_ENABLED=true
```

### 第三步：一键构建并启动容器

```bash
docker compose up -d --build
```

查看实时运行日志：
```bash
docker compose logs -f free4chat
```

出现 `Ready on http://0.0.0.0:3000` 即表示启动成功！在浏览器中打开 `http://<你的VPS公网IP>:3000` 即可开始创建房间！

---

## 3. 部署方式二：一键脚本自动化部署

项目根目录下提供了自动化向导脚本 `deploy.sh`，适合新手或快速安装：

```bash
chmod +x deploy.sh
./deploy.sh
```

向导将自动执行：
1. 检测并安装 Docker 与 Docker Compose 插件（如未安装）。
2. 自动检测 VPS 的公网 IP 并更新至 `.env`。
3. 提示选择：
   - **模式 1**：直接 HTTP 模式（端口 3000）。
   - **模式 2**：域名 + 自动申请 HTTPS 证书模式（端口 80/443）。
4. 自动编译容器、健康检测并输出访问地址及 Agent 接入指南。

---

## 4. 部署方式三：宿主机原生部署 (Node + Systemd)

如果你不使用 Docker，可以在 VPS 上直接通过 Node.js 运行服务：

### 1. 安装 Node.js 22 LTS
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g yarn
```

### 2. 编译应用
```bash
cd app
yarn install
# 编译生产包（带禁用 Turnstile 参数）
NEXT_PUBLIC_TURNSTILE_DISABLED=1 yarn cf-build
```

### 3. 配置 Systemd 常驻服务
复制项目根目录下的 `free4chat.service`：
```bash
sudo mkdir -p /opt/free4chat/data
sudo cp -r /path/to/free4chat/* /opt/free4chat/
sudo cp /opt/free4chat/free4chat.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now free4chat
```

查看运行状态：
```bash
sudo systemctl status free4chat
```

---

## 5. 域名与 HTTPS 证书配置

现代浏览器（Chrome、Safari 等）要求**只有在 `localhost` 或 `HTTPS` 环境下才允许调用麦克风和屏幕共享 API**。如果需要在公网正常使用语音，建议绑定域名并启用 HTTPS。

### 方案 A：使用内置 Caddy（零配置全自动 HTTPS）

1. 将你的域名解析（A 记录）指向 VPS 的公网 IP。
2. 编辑 `.env` 文件，填入你的域名：
   ```env
   DOMAIN=chat.yourdomain.com
   APP_URL=https://chat.yourdomain.com
   ```
3. 启用带 `ssl` 配置的容器：
   ```bash
   docker compose --profile ssl up -d
   ```
   Caddy 会全自动向 Let's Encrypt 申请 SSL 证书并自动配置 HTTP 跳转与 WebSocket 代理！

### 方案 B：使用已有的宿主机 Nginx

如果你服务器上已经有 Nginx 运行，可以使用项目中提供的 `nginx.conf` 模板配置：

```bash
sudo cp nginx.conf /etc/nginx/sites-available/free4chat
# 修改其中的域名
sudo nano /etc/nginx/sites-available/free4chat
sudo ln -s /etc/nginx/sites-available/free4chat /etc/nginx/sites-enabled/
sudo certbot --nginx -d chat.yourdomain.com
sudo systemctl reload nginx
```

---

## 6. 接入与运行 AI Agent

Free4Chat 原生支持独立运行的 AI Agent（如 Claude、Codex、Pi、Hermes 等）作为第一公民加入房间协同工作。

### 1. 编译 Agent 运行库

项目 `agent/` 目录包含了高性能、自包含的 Go Agent Runtime：

```bash
# 编译当前系统的 Agent 二进制
cd agent
go build -o free4chat-agent ./cmd/free4chat-agent
```

若需交叉编译为 Linux 独立二进制：
```bash
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o free4chat-agent-linux ./cmd/free4chat-agent
```

### 2. 让 Agent 加入房间

进入任何网页房间后，点击房间顶部的 **Invite Agent**（邀请 Agent），将生成的引导提示词发送给你的 Agent。

或者在终端直接使用命令行让 Agent 加入：

```bash
./free4chat-agent room join <房间ID> \
  --mcp-endpoint http://<你的VPS公网IP>:3000/mcp \
  --agent codex \
  --name "Codex-Bot"
```

Agent 将立即在网页端显示上线，并能接收 @提及、协同任务分派（Task）、生成并发布交互式应用（Mini-App）与实时审批！

---

## 7. 开启 WebRTC 语音与屏幕共享 (可选)

在默认自建模式下，Free4Chat 开启了模拟 SFU 模式，文字聊天、文件传输、Agent 协作均正常可用。

如果你希望在自建版本中开启高品质的**多人群组实时语音通话**和**屏幕共享**：

1. 注册一个免费的 [Cloudflare 账号](https://dash.cloudflare.com/)。
2. 进入控制台左侧 **Calls** (Realtime SFU)。
3. 点击 **Create App** 创建一个应用，获取：
   - `App ID`
   - `App Secret`
   *(Cloudflare 每月向每个账号免费提供 10,000 分钟通话时长，完全足够个人与团队日常使用)*。
4. 将密钥填入 `.env` 文件：
   ```env
   SFU_APP_ID=你的_Cloudflare_SFU_App_Id
   SFU_APP_SECRET=你的_Cloudflare_SFU_App_Secret
   SFU_MOCK_ENABLED=false
   ```
5. 重启容器生效：
   ```bash
   docker compose restart
   ```
   重启后，语音通话与屏幕共享将无缝接入 Cloudflare 全球低延迟 WebRTC 边缘中继！

---

## 8. 数据备份与目录结构

所有持久化数据（房间状态、活跃租约、Durable Object 存储、KV 缓存）都保存在项目目录下的 `./data` 目录中：

```text
free4chat/
├── data/                      # 核心持久化存储（自动映射至容器 /data）
│   └── v3/
│       ├── do/                # Durable Objects SQLite 数据库（房间与任务状态）
│       └── kv/                # KV 缓存与租约
├── .env                       # 部署配置文件
├── docker-compose.yml         # 容器编排定义
├── Dockerfile                 # 多阶段生产镜像构建文件
├── Caddyfile                  # Caddy 自动化 SSL 反代配置
├── nginx.conf                 # Nginx 反代配置参考
└── deploy.sh                  # 一键部署与维护脚本
```

**备份与迁移**：
只需备份 `.env` 文件和 `data/` 目录即可：
```bash
tar -czvf free4chat_backup_$(date +%F).tar.gz .env data/
```

---

## 9. 常见问题解答 (FAQ)

### Q1: 页面显示 "Microphone permission denied" 无法开麦？
**原因**：现代浏览器出于安全隐私限制，只允许在 `http://localhost` 或 `https://` 域名协议下访问麦克风与摄像头。
**解决办法**：请使用方式一配置 Caddy 或 Nginx 开启 HTTPS 访问。

### Q2: 出现 403 `forbidden_origin` 错误？
**原因**：访问的 Origin 未在白名单中。
**解决办法**：检查 `.env` 文件中是否已配置 `ALLOW_ANY_ORIGIN=true`，或在 `ALLOWED_ORIGINS` 中添加你访问的具体地址（包括协议与端口，例如 `http://1.2.3.4:3000`）。修改后运行 `docker compose up -d` 重新加载。

### Q3: AI Agent 无法通过 MCP 接口连接房间？
**原因**：访问的 Host 头未被允许。
**解决办法**：确保 `.env` 中 `ALLOW_ANY_HOST=true`；若使用命令行，请确保参数 `--mcp-endpoint` 填写的协议与路径正确，例如 `http://<VPS-IP>:3000/mcp`。

### Q4: 如何更新到最新代码？
```bash
git pull
docker compose up -d --build
```
`./data` 目录保持独立，更新过程不会影响原有房间数据。
