FROM python:3.12-slim

WORKDIR /app

# Устанавливаем зависимости без кеша
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копируем проект
COPY . .

# Создаём непривилегированного пользователя и передаём ему права на /app
RUN groupadd --system app && useradd --system --create-home --gid app --uid 1000 --shell /usr/sbin/nologin appuser \
    && chown -R appuser:app /app

# Запуск от non-root
USER 1000

EXPOSE 8080

# Healthcheck: однострочная команда для python -c (совместимо с Dockerfile)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import sys,urllib.request; \
import urllib.error; \
import socket; \
url='http://127.0.0.1:8080/healthz'; \
timeout=2; \
try: \
    r=urllib.request.urlopen(url, timeout=timeout); \
    sys.exit(0 if getattr(r,'status',200)==200 else 1); \
except (urllib.error.URLError,urllib.error.HTTPError,socket.timeout,ConnectionError): \
    sys.exit(1)"

# Запуск uvicorn (порт/хост уже используются в compose/k8s)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080", "--timeout-keep-alive", "5"]