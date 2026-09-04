```markdown
# RemnaNode Installer

Универсальный скрипт для быстрой установки **Remnawave Node** на любой Linux-сервер (Ubuntu / Debian).

---

## Быстрый запуск (одна команда)

```bash
curl -fsSL https://raw.githubusercontent.com/eEkcoffEe/remnanode-installer/main/install.sh | bash -s -- "ВАШ_SECRET_KEY" [SSH_PORT] [порт1] [порт2] ...
```

### Примеры:

```bash
# Минимальный запуск (SSH = 20001, открыты 2222 и 443)
curl -fsSL https://raw.githubusercontent.com/eEkcoffEe/remnanode-installer/main/install.sh | bash -s -- "my-secret-key"

# Со своим SSH-портом
curl -fsSL https://raw.githubusercontent.com/eEkcoffEe/remnanode-installer/main/install.sh | bash -s -- "my-secret-key" 22222

# Со своим SSH-портом + дополнительные порты
curl -fsSL https://raw.githubusercontent.com/eEkcoffEe/remnanode-installer/main/install.sh | bash -s -- "my-secret-key" 20001 80 443 8443 10000
```

### Параметры

| Параметр       | Обязательный | По умолчанию | Описание                          |
|----------------|--------------|--------------|-----------------------------------|
| `SECRET_KEY`   | Да           | —            | Секретный ключ ноды               |
| `SSH_PORT`     | Нет          | `20001`      | Новый порт SSH                    |
| `порт1 порт2…` | Нет          | —            | Дополнительные порты для UFW      |

---

## Что делает скрипт

1. Обновляет систему (`apt update && apt upgrade`)
2. Устанавливает Docker и UFW
3. Создаёт `/opt/remnanode/docker-compose.yml` с вашим `SECRET_KEY`
4. Запускает контейнер `remnawave/node:latest`
5. Меняет SSH-порт (поддерживает `sshd` и `ssh.socket`)
6. Настраивает UFW:
   - Открывает новый SSH-порт
   - Открывает порт ноды `2222`
   - Открывает `443`
   - Открывает все дополнительные порты, которые вы указали
   - Закрывает порт `22`

---

## Ручная установка

```bash
curl -fsSL https://raw.githubusercontent.com/eEkcoffEe/remnanode-installer/main/install.sh -o install.sh
chmod +x install.sh

# Запуск
./install.sh "ВАШ_SECRET_KEY" 20001 80 443 8443
```

---

## Требования

- Ubuntu 20.04 / 22.04 / 24.04 или Debian 11/12
- Права root
- Доступ в интернет

---

## После установки

```bash
docker ps --filter name=remnanode
ufw status verbose
ss -tlnp | grep -E ':20001|:2222'
```

**Важно:** сразу проверьте подключение по новому SSH-порту, пока текущая сессия ещё открыта.

---

## Автор

[eEkcoffEe](https://github.com/eEkcoffEe)
```
