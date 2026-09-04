Готово. Вот актуальные данные под твой репозиторий:

### Команда для прямого запуска

```bash
curl -fsSL https://raw.githubusercontent.com/eEkcoffEe/remnanode-installer/main/install.sh | bash -s -- "ВАШ_SECRET_KEY" 20001
```

**Пример:**
```bash
curl -fsSL https://raw.githubusercontent.com/eEkcoffEe/remnanode-installer/main/install.sh | bash -s -- "my-super-secret-key-123" 20001
```

---

### README.md (готовый к загрузке)

```markdown
# RemnaNode Installer

Универсальный скрипт для быстрой установки **Remnawave Node** на любой Linux-сервер (Ubuntu / Debian).

---

## Быстрый запуск (одна команда)

```bash
curl -fsSL https://raw.githubusercontent.com/eEkcoffEe/remnanode-installer/main/install.sh | bash -s -- "ВАШ_SECRET_KEY" 20001
```

### Пример:
```bash
curl -fsSL https://raw.githubusercontent.com/eEkcoffEe/remnanode-installer/main/install.sh | bash -s -- "super-secret-key-12345" 20001
```

| Параметр     | Обязательный | По умолчанию | Описание              |
|--------------|--------------|--------------|-----------------------|
| `SECRET_KEY` | Да           | —            | Секретный ключ ноды   |
| `SSH_PORT`   | Нет          | `20001`      | Новый порт SSH        |

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
   - Закрывает порт `22`

---

## Ручная установка

```bash
curl -fsSL https://raw.githubusercontent.com/eEkcoffEe/remnanode-installer/main/install.sh -o install.sh
chmod +x install.sh
./install.sh "ВАШ_SECRET_KEY" 20001
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

---

Скопируй `README.md` в репозиторий и загрузи скрипт как `install.sh`.  

Хочешь, я ещё раз выведу полный актуальный `install.sh` под твой репозиторий?