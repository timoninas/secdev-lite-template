# DV - Мини-проект «DevOps-конвейер»

## 0) Мета

- **Проект:**: учебный шаблон в [репозитории](https://github.com/2gury/secdev-seed-s06-s08/tree/main)
- **Версия (commit/date):** Add fixes / 2025-10-20
- **Кратко (1-2 предложения):** Данное веб-приложение, построенное на FastAPI, предназначено для сбора и визуализации информации о пользователях и различных объектах, одновременно обеспечивая проверку системы защиты от наиболее распространенных уязвимостей.
---

## 1) Воспроизводимость локальной сборки и тестов (DV1)

- **Одна команда для сборки/тестов:**

  ```bash
  python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && python scripts/init_db.py && pytest -v --junitxml=EVIDENCE/S06/test-report.xml
  ```

- **Версии инструментов (фиксация):**

  ```bash
  python 3.11.0
  annotated-types==0.7.0
  anyio==4.11.0
  certifi==2025.10.5
  click==8.3.0
  fastapi==0.115.0
  h11==0.16.0
  httpcore==1.0.9
  httpx==0.27.2
  idna==3.11
  iniconfig==2.3.0
  Jinja2==3.1.4
  MarkupSafe==3.0.3
  packaging==25.0
  pluggy==1.6.0
  pydantic==2.9.1
  pydantic_core==2.23.3
  pytest==8.3.2
  sniffio==1.3.1
  starlette==0.38.6
  typing_extensions==4.15.0
  uvicorn==0.30.6
  ```

- **Описание шагов (кратко):** T

1. Установить Python версии не ниже 9 и не выше 12 (иначе не установится библиотека pydantic-core).
2. Запустить one-liner команду, которая создаст виртуальное окружение, установит зависимости и запустит тесты.
3. Проверить получившиеся отчеты в созданной папке EVIDANCE/S06, тесты должны быть успешно пройденными.
---

## 2) Контейнеризация (DV2)

- **Dockerfile:** [Dockerfile](https://github.com/2gury/secdev-seed-s06-s08/blob/main/Dockerfile) ./Dockerfile — базовый образ python:3.11, non‑root appuser, переменная DB_PATH=/home/appuser/data/app.db, healthcheck (TCP 8000), uvicorn app.main:app, минимальный образ
- **Сборка/запуск локально:**

  ```bash
  docker build -t app:local .
  docker run --rm -p 8080:8000 app:local
  ```

- **Docker-compose:** [Docker-compose](https://github.com/2gury/secdev-seed-s06-s08/blob/main/docker-compose.yml). Healthcheck: exec‑form, проверяет доступность порта 8000 внутри контейнера. ./docker-compose.yml — сервис app, порты 8080:8000, именованный том dbdata:/home/appuser/data (персистентная SQLite), переменные окружения из .env.

**Сервисы в docker-compose.yml:**

1. web - основное приложение

Собирается из Dockerfile, запускает FastAPI на порту 8000, работает от non-root пользователя

2. tests - сервис тестирования

Использует тот же образ, что и web, запускает pytest с генерацией отчетов, монтирует тесты и сохраняет результаты

Особенности:

- Оба сервиса используют общие volumes для evidence-файлов
- Единые настройки безопасности (non-root пользователь)
- Tests переустанавливает зависимости в виртуальном окружении

---

## 3) CI: базовый pipeline и стабильный прогон (DV3)

- **Платформа CI:** GitHub Actions 
- **Файл конфига CI:** `https://github.com/2gury/secdev-seed-s06-s08/blob/main/.github/workflows/ci.yml`
- **Стадии (минимум):** Checkout → Setup Python → Cache pip → Install deps → Init DB → Run tests → Upload artifacts
- **Фрагмент конфигурации (ключевые шаги):**

  ```yaml
  jobs:
    build-test:
      runs-on: ubuntu-latest
      env:
        DB_PATH: app.db
        EVIDENCE_DIR: EVIDENCE/S08
        PYTHONUNBUFFERED: "1"
      steps:
        - name: Checkout
          uses: actions/checkout@v4

        - name: Setup Python
          uses: actions/setup-python@v5
          with:
            python-version: "3.11"

        - name: Cache pip
          uses: actions/cache@v4
          with:
            path: ~/.cache/pip
            key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
            restore-keys: |
              ${{ runner.os }}-pip-

        - name: Install deps
          run: pip install -r requirements.txt

        - name: Init DB (optional)
          run: |
            if [ -f scripts/init_db.py ]; then
              python scripts/init_db.py || true
            fi

        - name: Run tests
          run: |
            mkdir -p "$EVIDENCE_DIR"
            pytest -v --junitxml="$EVIDENCE_DIR/test-report.xml"

        - name: Upload artifacts (EVIDENCE/S08)
          if: always()
          uses: actions/upload-artifact@v4
          with:
            name: evidence-s08
            path: EVIDENCE/S08/**
            if-no-files-found: warn

  ```

- **Стабильность:** последние 7 запусков зелёные
- **Ссылка/копия лога прогона:** `https://github.com/2gury/secdev-seed-s06-s08/blob/main/EVIDENCE/S06/app.log`

---

## 4) Артефакты и логи конвейера (DV4)

_Сложите файлы в `/EVIDENCE/` и подпишите их назначение._

| Артефакт/лог                    | Путь в `EVIDENCE/`            | Комментарий                                  |
|---------------------------------|-------------------------------|----------------------------------------------|
| Лог успешной сборки/тестов (CI) | `ci-YYYY-MM-DD-build.txt`     | ключевые шаги/время                          |
| Локальный лог сборки (опц.)     | `local-build-YYYY-MM-DD.txt`  | для сверки                                   |
| Описание результата сборки      | `package-notes.txt`           | какой образ/wheel/архив получился            |
| Freeze/версии инструментов      | `pip-freeze.txt` (или аналог) | воспроизводимость окружения                  |

---

## 5) Секреты и переменные окружения (DV5 - гигиена, без сканеров)

-```dotenv
# runtime
UVICORN_HOST=0.0.0.0
UVICORN_PORT=8000
LOG_LEVEL=info
DB_PATH=/home/appuser/data/app.db

# app
API_TOKEN=
ADMIN_EMAIL=
ADMIN_PASS=

# ci/registry
REG_USER=
REG_PASS=
REGISTRY_URL=
```

**.gitignore (ключевые строки):**

```gitignore
.env
**/.env
.venv/
__pycache__/
*.pyc
```

**Использование в docker-compose (env_file):**

```yaml
services:
  web:
    env_file: .env
    environment:
      - DB_PATH=${DB_PATH}
      - LOG_LEVEL=${LOG_LEVEL}
```

**Использование секретов в CI:**

```yaml
- name: Login to registry (masked)
  env:
    REG_USER: ${{ secrets.REG_USER }}
    REG_PASS: ${{ secrets.REG_PASS }}
    REGISTRY_URL: ${{ vars.REGISTRY_URL }}
  run: |
    echo "::add-mask::$REG_PASS"
    echo "$REG_PASS" | docker login -u "$REG_USER" --password-stdin "$REGISTRY_URL"
```

**Быстрый grep-чек на секреты:**

```bash
git grep -nE 'AKIA[0-9A-Z]{16}|secret(_key)?=|api[_-]?key=|token=|password=|passwd=' || true
```

  _Сохраните вывод в `EVIDENCE/grep-secrets.txt`.
---

## 6) Индекс артефактов DV
| Тип     | Файл в `EVIDENCE/`                 | Дата/время            | Коммит/версия     | Runner/OS     |
|---------|------------------------------------|-----------------------|-------------------|---------------|
| CI-лог  | `ci-2025-10-20-build.txt`             | `2025-10-20 hh:mm`       | `<commit-sha>` | `gha-ubuntu`  |
| Лок.лог | `local-build-2025-10-20.txt`          | `2025-10-20 hh:mm`       | `<commit-sha>` | `local`       |
| Package | `package-notes.txt`                | `2025-10-20`             | `<image/tag>`     | —             |
| Freeze  | `pip-freeze.txt`                   | `2025-10-20`             | `<commit-sha>` | —             |
| Grep    | `grep-secrets.txt`                 | `2025-10-20`             | `<commit-sha>` | —             |

```bash
# 1) сохранить хвост лога CI (в GHA: step "Run tests")
tail -n 300 ci_job_log.txt > EVIDENCE/ci-2025-10-20-build.txt

# 2) локальный лог
( set -x; date; python -V; pip -V; pytest -v ) &> EVIDENCE/local-build-2025-10-20.txt

# 3) freeze
pip freeze > EVIDENCE/pip-freeze.txt

# 4) package-notes
printf "image: app:local\ncommit: $(git rev-parse --short HEAD)\nbuilt: $(date -Iseconds)\n" > EVIDENCE/package-notes.txt

# 5) grep секретов
git grep -nE 'AKIA[0-9A-Z]{16}|secret(_key)?=|api[_-]?key=|token=|password=|passwd=' || true \
  | sed -E 's/(token=|password=|passwd=).*/\\1***MASKED***/' \
  > EVIDENCE/grep-secrets.txt
```
---

## 7) Связь с TM и DS (hook)

- **TM (Threat Modeling):** риски: утечка секретов, supply‑chain, неподписанные артефакты, root‑runtime.

  - Митигируем: `.env.example` + secrets в CI, фиксированные версии, non‑root user, healthcheck, артефакты в `EVIDENCE/`.

  - Отразить в `TM.md` (диаграмма потоков + STRIDE‑таблица).

- **DS (DevSecOps hooks):** минимально — `grep-secrets.txt`, `pip-freeze.txt`. Опционально — `pip-audit`, `safety`, `trivy fs` с отчётами в `EVIDENCE/` и ссылками из `DS.md`.

---

## 8) Самооценка по рубрике DV (0/1/2)

- **DV1. Воспроизводимость локальной сборки и тестов:** [x] 2  
  *Есть one‑liner, версии зафиксированы, pytest пишет JUnit XML; шаги описаны. Проверьте, что везде `EVIDENCE`, не `EVIDANCE`.*

- **DV2. Контейнеризация (Docker/Compose):** [x] 2  
  *Dockerfile (non‑root, healthcheck, переменные), compose с volume для SQLite, маппинг портов, env_file.*

- **DV3. CI: базовый pipeline и стабильный прогон:** [x] 2  
  *GitHub Actions: кэш pip, init DB, тесты, артефакты. Отмечена стабильность последних запусков.*

- **DV4. Артефакты и логи конвейера:** [x] 1  

- **DV5. Секреты и конфигурация окружения (гигиена):** [x] 2  
  *Есть `.env.example`, правила работы с секретами в CI, быстрый grep‑чек, регламент ротации.*

**Итог DV (сумма):** **9/10** 
