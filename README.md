# SEO-агент Royal Cargo

Автоматическая система мониторинга и анализа телефонных звонков для таможенного брокера **Royal Cargo**.

## Что делает

1. **Мониторит** звонки менеджеров в Bitrix24 каждые 10 минут
2. **Скачивает** MP3-записи разговоров
3. **Транскрибирует** аудио через Groq Whisper (~1 сек на файл)
4. **Сохраняет** расшифровку в базу данных PostgreSQL
5. **Анализирует** качество разговора через Claude AI
6. **Отправляет** отчёт руководителю в Telegram с оценкой 🟢 / 🟡 / 🔴

## Архитектура

```
Bitrix24 (звонки)
      │
      ▼
watcher.py  ──── polling каждые 10 мин ────▶  Groq Whisper
(Flask, Coolify)                                    │
      │                                         транскрипт
      │                                             │
      ▼                                             ▼
PostgreSQL (call_transcripts) ◀─────────────────────┘
      │
      ▼
audit.py  ──── Claude AI ────▶  Telegram (руководителю)
(cron, каждые 10 мин)
```

**watcher.py** — Flask-сервер, задеплоен на Coolify. Polling каждые 10 минут опрашивает 4 cargo-менеджеров и входящие необработанные лиды. Webhook `/webhook` принимает события Bitrix24 как резервный канал.

**audit.py** — читает новые записи из БД (`tg_sent=FALSE`), отправляет расшифровку в Claude, получает оценку разговора и краткое резюме, шлёт отчёт в Telegram.

**check_db.py** — email-уведомления о новых расшифровках (cron, пн-пт 9-18 МСК).

## Стек

| Компонент | Технология |
|---|---|
| Транскрипция | Groq Whisper API (`whisper-large-v3-turbo`) |
| Анализ | Anthropic Claude (`claude-sonnet-4-6`) |
| CRM | Bitrix24 REST API |
| База данных | PostgreSQL (psycopg2) |
| Сервер | Flask + Coolify (Docker) |
| Уведомления | Telegram Bot API |

## Деплой

Сервер работает на Coolify по адресу `https://agentseven.tamozhennybrokeragents.ru`.

```bash
# Проверить статус
curl https://agentseven.tamozhennybrokeragents.ru/health

# Запустить polling вручную
curl https://agentseven.tamozhennybrokeragents.ru/poll
```

Деплой происходит автоматически при `git push` в `main`.

## Переменные окружения

Все секреты хранятся в `.env` (не коммитится). Необходимые переменные:

```
BITRIX_PORTAL, BITRIX_USER_ID, BITRIX_TOKEN
GROQ_API_KEY
CLAUDE_API_KEY, CLAUDE_MODEL
Postgres_URL
TG_BOT_TOKEN_AUDIT
BITRIX_WEBHOOK_TOKEN
BITRIX_ID_* (ID менеджеров)
```

## Roadmap

- [x] Polling Bitrix24 + транскрипция звонков
- [x] Аудит качества через Claude → Telegram
- [ ] Генерация SEO-статей на основе транскриптов
- [ ] Согласование статей через Telegram
- [ ] Публикация в CMS
- [ ] Видео из статьи → соцсети
