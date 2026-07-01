FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc cron && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Cron: worker.py каждые 5 минут + check_db.py каждые 20 минут
RUN printf '*/5 * * * * cd /app && python3 worker.py >> /var/log/worker.log 2>&1\n*/20 * * * * cd /app && python3 check_db.py >> /var/log/check_db.log 2>&1\n' > /etc/cron.d/worker \
    && chmod 0644 /etc/cron.d/worker \
    && crontab /etc/cron.d/worker

EXPOSE 8000

# Запускаем cron + Flask одновременно
CMD cron && python3 watcher.py
