#!/bin/bash

set -euo pipefail

# ====================== Параметры ======================
SECRET_KEY="${1:-}"
NEW_SSH_PORT="${2:-20001}"
NODE_PORT=2222

# Все аргументы после второго — дополнительные порты
shift 2 2>/dev/null || true
EXTRA_PORTS=("$@")

if [[ -z "$SECRET_KEY" ]]; then
    echo "Ошибка: нужно указать SECRET_KEY"
    echo
    echo "Использование:"
    echo "  $0 <SECRET_KEY> [SSH_PORT] [доп.порт1] [доп.порт2] ..."
    echo
    echo "Примеры:"
    echo "  $0 \"my-secret\""
    echo "  $0 \"my-secret\" 22222"
    echo "  $0 \"my-secret\" 20001 80 443 8443"
    exit 1
fi

echo "=============================================="
echo " SECRET_KEY     = $SECRET_KEY"
echo " SSH Port       = $NEW_SSH_PORT"
echo " Node Port      = $NODE_PORT"
echo " Extra ports    = ${EXTRA_PORTS[*]:-нет}"
echo "=============================================="
echo

# ====================== Проверка: уже установлена ли нода ======================
NODE_ALREADY_INSTALLED=false

if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^remnanode$"; then
    echo "[!] Контейнер remnanode уже существует — пропускаю установку ноды"
    NODE_ALREADY_INSTALLED=true
elif [[ -d /opt/remnanode ]] && [[ -f /opt/remnanode/docker-compose.yml ]]; then
    echo "[!] Директория /opt/remnanode уже существует — пропускаю установку ноды"
    NODE_ALREADY_INSTALLED=true
fi

# ====================== 1. Обновление системы + UFW ======================
echo "[1/6] Обновление системы и установка UFW..."
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y
apt install -y ufw curl ca-certificates

# ====================== 2-4. Установка Docker + ноды (только если ещё не стоит) ======================
if [[ "$NODE_ALREADY_INSTALLED" == false ]]; then
    echo "[2/6] Установка Docker..."
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    else
        echo "Docker уже установлен"
    fi

    # Docker Compose plugin
    if ! docker compose version &>/dev/null; then
        apt install -y docker-compose-plugin || true
    fi

    echo "[3/6] Настройка remnanode..."
    mkdir -p /opt/remnanode
    cd /opt/remnanode

    cat > docker-compose.yml <<EOF
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:latest
    network_mode: host
    restart: always
    cap_add:
      - NET_ADMIN
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    environment:
      - NODE_PORT=${NODE_PORT}
      - SECRET_KEY=${SECRET_KEY}
EOF

    echo "docker-compose.yml создан"

    echo "[4/6] Запуск контейнера..."
    docker compose pull
    docker compose up -d

    sleep 3
    docker ps --filter name=remnanode
else
    echo "[2-4/6] Установка ноды пропущена (уже установлена)"
fi

# ====================== 5. Смена SSH-порта ======================
echo "[5/6] Смена SSH-порта на ${NEW_SSH_PORT}..."

if systemctl is-active --quiet ssh.socket 2>/dev/null; then
    echo "Обнаружен systemd ssh.socket"
    mkdir -p /etc/systemd/system/ssh.socket.d
    cat > /etc/systemd/system/ssh.socket.d/override.conf <<EOF
[Socket]
ListenStream=
ListenStream=${NEW_SSH_PORT}
EOF
    systemctl daemon-reload
    systemctl restart ssh.socket
    echo "ssh.socket перенастроен"
else
    echo "Обычный sshd"
    CONFIG="/etc/ssh/sshd_config"
    cp -a "$CONFIG" "${CONFIG}.backup.$(date +%Y%m%d-%H%M%S)"

    if grep -Eq '^[[:space:]]*Port[[:space:]]+[0-9]+' "$CONFIG"; then
        sed -i -E "s|^[[:space:]]*Port[[:space:]]+[0-9]+|Port ${NEW_SSH_PORT}|" "$CONFIG"
    else
        echo "Port ${NEW_SSH_PORT}" >> "$CONFIG"
    fi

    sed -i -E 's|^[[:space:]]*#?[[:space:]]*Port[[:space:]]+22|#Port 22|' "$CONFIG" || true

    if ! sshd -t; then
        echo "Ошибка в конфигурации sshd!"
        exit 1
    fi

    systemctl restart ssh || systemctl restart sshd
    echo "sshd перенастроен"
fi

# ====================== 6. Настройка UFW ======================
echo "[6/6] Настройка файрвола UFW..."

ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Основные порты
ufw allow ${NEW_SSH_PORT}/tcp comment 'SSH'
ufw allow ${NODE_PORT}/tcp comment 'Remnanode'
ufw allow 443/tcp comment 'HTTPS'

# Дополнительные порты, которые указал пользователь
for port in "${EXTRA_PORTS[@]}"; do
    if [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "  + разрешаю порт $port"
        ufw allow ${port}/tcp comment "Extra port"
    else
        echo "  ! пропущен некорректный порт: $port"
    fi
done

# Удаляем 22
ufw delete allow 22/tcp 2>/dev/null || true
ufw delete allow 22 2>/dev/null || true

ufw --force enable

echo
echo "=============================================="
echo " Готово!"
echo "=============================================="
echo
echo "Статус контейнера:"
docker ps --filter name=remnanode 2>/dev/null || echo "Контейнер не найден"
echo
echo "Открытые порты:"
ss -tlnp | grep -E ":${NEW_SSH_PORT}|:${NODE_PORT}|:443" || true
echo
echo "Статус UFW:"
ufw status verbose
echo
echo "Важно: проверьте SSH-подключение на порт ${NEW_SSH_PORT}"
echo