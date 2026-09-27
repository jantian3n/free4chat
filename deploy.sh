#!/usr/bin/env bash
# ==============================================================================
# Free4Chat 单 VPS 一键部署与管理脚本 (Free4Chat VPS Deployment Script)
# ==============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}       Free4Chat 单 VPS 一键部署向导 (Self-Hosted)     ${NC}"
echo -e "${BLUE}======================================================${NC}"

# 1. 检查 Docker 环境
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${YELLOW}[!] 检测到未安装 Docker。正在尝试自动安装 Docker...${NC}"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker || true
  else
    echo -e "${RED}[X] 缺少 curl，无法自动安装 Docker。请先手动安装 docker: apt update && apt install -y docker.io docker-compose-plugin${NC}"
    exit 1
  fi
fi

if ! docker compose version >/dev/null 2>&1; then
  echo -e "${RED}[X] 检测到未安装 docker compose 插件。请运行: apt install -y docker-compose-plugin${NC}"
  exit 1
fi

echo -e "${GREEN}[✓] Docker 与 Docker Compose 准备就绪${NC}"

# 2. 检查并准备 .env 文件
if [ ! -f .env ]; then
  echo -e "${YELLOW}[*] 未检测到 .env 配置文件，正在从 .env.example 复制...${NC}"
  cp .env.example .env

  # 自动检测机器公网 IP
  PUBLIC_IP=$(curl -s -m 5 https://api.ipify.org 2>/dev/null || curl -s -m 5 https://icanhazip.com 2>/dev/null || echo "")
  if [ -n "$PUBLIC_IP" ]; then
    echo -e "${GREEN}[*] 检测到公网 IP: ${PUBLIC_IP}${NC}"
    # 替换 APP_URL
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|APP_URL=http://localhost:3000|APP_URL=http://${PUBLIC_IP}:3000|g" .env
    else
      sed -i "s|APP_URL=http://localhost:3000|APP_URL=http://${PUBLIC_IP}:3000|g" .env
    fi
  fi
fi

# 3. 部署模式选择
echo ""
echo "请选择部署模式 (Select Deployment Mode):"
echo "  1) 直接部署 (HTTP, 端口 3000) [默认]"
echo "  2) 域名 + 自动 HTTPS 证书部署 (使用 Caddy 反代, 端口 80/443)"
read -r -p "请输入序号 [1/2, 默认 1]: " DEPLOY_MODE
DEPLOY_MODE=${DEPLOY_MODE:-1}

COMPOSE_CMD="docker compose"

if [ "$DEPLOY_MODE" = "2" ]; then
  read -r -p "请输入你的域名 (例如 chat.example.com): " INPUT_DOMAIN
  if [ -n "$INPUT_DOMAIN" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|DOMAIN=.*|DOMAIN=${INPUT_DOMAIN}|g" .env
      sed -i '' "s|APP_URL=.*|APP_URL=https://${INPUT_DOMAIN}|g" .env
    else
      sed -i "s|DOMAIN=.*|DOMAIN=${INPUT_DOMAIN}|g" .env
      sed -i "s|APP_URL=.*|APP_URL=https://${INPUT_DOMAIN}|g" .env
    fi
    echo -e "${GREEN}[✓] 域名已设置为: ${INPUT_DOMAIN}${NC}"
    COMPOSE_CMD="docker compose --profile ssl"
  else
    echo -e "${YELLOW}[!] 域名输入为空，将使用默认 HTTP 模式部署。${NC}"
  fi
fi

# 4. 构建与启动容器
echo ""
echo -e "${BLUE}[*] 正在构建并启动 Free4Chat 容器... (首次编译可能需要 1~2 分钟)${NC}"
$COMPOSE_CMD up -d --build

echo ""
echo -e "${BLUE}[*] 正在检查服务健康状态...${NC}"
RETRIES=15
SUCCESS=0
for i in $(seq 1 $RETRIES); do
  sleep 2
  if curl -s -f http://127.0.0.1:3000/ >/dev/null 2>&1; then
    SUCCESS=1
    break
  fi
  echo -n "."
done

echo ""
if [ $SUCCESS -eq 1 ]; then
  APP_URL_CONF=$(grep "^APP_URL=" .env | cut -d '=' -f2- || echo "http://localhost:3000")
  echo -e "${GREEN}======================================================${NC}"
  echo -e "${GREEN} 🎉 Free4Chat 单 VPS 服务部署成功！                  ${NC}"
  echo -e "${GREEN}======================================================${NC}"
  echo -e " 🌐 房间访问地址:     ${BLUE}${APP_URL_CONF}${NC}"
  echo -e " 🤖 MCP Agent 端点:   ${BLUE}${APP_URL_CONF}/mcp${NC}"
  echo -e " 📁 数据存储目录:     ./data (已持久化挂载)"
  echo ""
  echo -e "${YELLOW}【常用维护命令】${NC}"
  echo " 查看运行日志:   docker compose logs -f free4chat"
  echo " 停止服务:       docker compose down"
  echo " 重启服务:       docker compose restart"
  echo ""
  echo -e "${YELLOW}【接入外部 AI Agent 示例】${NC}"
  echo " 编译或下载 free4chat-agent 运行库后，在任何机器上执行:"
  echo " free4chat-agent room join <房间ID> --mcp-endpoint ${APP_URL_CONF}/mcp --agent codex"
  echo -e "${GREEN}======================================================${NC}"
else
  echo -e "${YELLOW}[!] 服务已启动，但在健康检查时间内未返回 200。请查看日志排查:${NC}"
  echo " docker compose logs -f free4chat"
fi
