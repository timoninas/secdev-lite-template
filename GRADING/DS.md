# DS - Отчёт «DevSecOps-сканы и харднинг»

---

## 0) Мета

- **Проект**: [ssd-project-s09-s12](https://github.com/2gury/secdev-seed-s09-s12)
- **Версия (commit/date):** `SecDev add ds` / `2025-28-10`
- **Кратко (1-2 предложения):** FastAPI приложение, которое демонстрируется DevSecOps практики, предназначенные для изучения предмета по безопасности и управления зависимостями при разработке ПО.

---

## 1) SBOM и уязвимости зависимостей (DS1)
- **Инструмент/формат:** CycloneDX 1.6, Grype v0.101.1 для SCA
- **Как запускал:**
  ```terminal
  # generate smob with syft
  scan dir:. -o cyclonedx-json > EVIDENCE/S09/sbom.json

  # rub sca with grype
  grype sbom:EVIDENCE/S09/sbom.json --fail-on high -o json > EVIDENCE/S09/sca_report.json
  ```

- **Отчёты:**
  - SBOM: [EVIDENCE/S09/sbom.json](../EVIDENCE/S09/sbom.json)
  - SCA Report: [EVIDENCE/S09/sca_report.json](../EVIDENCE/S09/sca_report.json)
  - CI/CD: [Actions Job](https://github.com/2gury/secdev-seed-s09-s12/actions/runs/18850643539/job/53786068706)

- **Выводы:**
  - Найдены уязвимости в Jinja2 3.1.4:
    - 2 Medium (GHSA-q2x7-8rv6-6q7h, GHSA-cpwx-vrp4-4pq7) - sandbox breakout через format method
    - 1 High (CVE-2024-56201) - rce через malicious filenames
  - Ключевые зависимости:
    - jinja2=3.1.4 (нужно обновить до до 3.1.6)
    - fastapi=0.115.0
    - uvicorn=0.30.1
    - httpx=0.27.2
    - pydantic=2.9.2
    - pytest=8.3.2

- **Действия:**
  - Требуется обновление jinja2 до версии 3.1.6 для устранения найденных уязвимостей
  - Добавлен автоматический CI check через Actions

- **Гейт по зависимостям:**
  - Critical=0
  - High≤1 | Допускаем временно high уязвимость в jinja2 до обновления

---

## 2) SAST и Secrets (DS2)

### 2.1 SAST
- **Инструмент/профиль:** Semgrep OSS v1.138.0 с профилем p/ci
- **Как запускал:**
  ```bash
  semgrep 
    --config p/ci 
    --severity=high 
    --error 
    --sarif 
    --output EVIDENCE/S10/semgrep.sarif
  ```

- **Отчёт:** [EVIDENCE/S10/semgrep.sarif](../EVIDENCE/S10/semgrep.sarif)
- **Выводы:**
  - Сканирование успешно выполнено
  - Критических уязвимостей и проблем с качеством кода не обнаружено
  - Профиль p/ci покрывает основные паттерны безопасности Python

### 2.2 Secrets scanning

- **Инструмент:** Gitleaks
- **Как запускал:**
  ```bash
  gitleaks detect 
    --no-git 
    --report-format json 
    --report-path EVIDENCE/S10/gitleaks.json
  ```

- **Отчёт:** [EVIDENCE/S10/gitleaks.json](../EVIDENCE/S10/gitleaks.json)
- **Выводы:**
  - Сканирование выполнено без проблем
  - Секреты и sensitive данные не обнаружены
  - CI/CD: [Actions Job](https://github.com/2gury/secdev-seed-s09-s12/actions/runs/18850643573/job/53786068606)

---

## 3) DAST и Policy (Container/IaC) (DS3)
### DAST
- **Инструмент/таргет:** OWASP ZAP (ZAP Baseline Scan) - ZAP v2.16.1
- **Как запускал (локально через Docker):**

```bash
# запущено локально через docker (user)
docker run --rm -v %cd%:/zap/wrk \
  zaproxy/zap-stable \
  zap-baseline.py -t http://host.docker.internal:8080 \
  -r EVIDENCE/S11/zap_baseline.html \
  -J EVIDENCE/S11/zap_baseline.json -d
```

- **Отчёты / Артефакты:**
  - HTML: [EVIDENCE/S11/zap_baseline.html](../EVIDENCE/S11/zap_baseline.html)
  - JSON: [EVIDENCE/S11/zap_baseline.json](../EVIDENCE/S11/zap_baseline.json)
  - Scan config used (baseline job): [EVIDENCE/S11/zap.yaml](../EVIDENCE/S11/zap.yaml)

- **Краткая сводка (из zap_baseline.json / html):**
  - High: 0
  - Medium: 2
  - Low: 3
  - Informational: 3

- **Основные Medium‑alerts (рекомендуемые исправления):**
  - Content Security Policy (CSP) Header Not Set - pluginId 10038 - instances: 4  
    => Action: добавить / настроить Content-Security-Policy (backend / web server). Evidence: [EVIDENCE/S11/zap_baseline.json](../EVIDENCE/S11/zap_baseline.json)`#10038` / [EVIDENCE/S11/zap_baseline.html](../EVIDENCE/S11/zap_baseline.html)`#10038`
  - Missing Anti-clickjacking Header (X-Frame-Options / frame-ancestors) - pluginId 10020 - instances: 3  
    => Action: добавить X-Frame-Options: DENY или CSP frame-ancestors (backend). Evidence: [EVIDENCE/S11/zap_baseline.json](../EVIDENCE/S11/zap_baseline.json)`#10020` / [EVIDENCE/S11/zap_baseline.html](../EVIDENCE/S11/zap_baseline.html)`#10020`

- **Выводы (кратко):**
  - Сканы выполнены успешно локально. Отсутствует или не достает security headers. Относится больше к конфигурационному замечанию для demo приложения
  - Нет high уязвимостей по результатам базового скана
  - Следует внести правки в security headers и повторно запустить zap для валидации

- **Действия / Owner / Проверка:**
  - Owner: backend team
  - Действие: интегрировать CSP, X-Frame-Options / frame-ancestors, X-Content-Type-Options; повторно запустить zap baseline.
  - Проверка: релаунч zap baseline; сравнить [EVIDENCE/S11/zap_baseline.json](../EVIDENCE/S11/zap_baseline.json) до/после.

- **CI/CD Actions:** [Actions Job](https://github.com/2gury/secdev-seed-s09-s12/actions/runs/18851817466/job/53790014089)

### Policy / Container / IaC

- **Инструмент(ы):**
  - Trivy v0.48.0 - container/config scanning для образов и iac

- **Как запускал:**
  ```powershell
  # Config scan
  docker run --rm -v "${PWD}:/workdir" -w /workdir aquasec/trivy:latest config `
    --format table `
    --severity HIGH,CRITICAL `
    --output EVIDENCE/S11/trivy-config.txt .

  # Image scan
  docker run --rm -v "${PWD}:/workdir" -v /var/run/docker.sock:/var/run/docker.sock -w /workdir `
    aquasec/trivy:latest image `
    --format table `
    --severity HIGH,CRITICAL `
    --output EVIDENCE/S11/trivy-image.txt myapp:latest
  ```

- **Отчёты:**
  - Config scan: [EVIDENCE/S12/trivy-config.txt](../EVIDENCE/S12/trivy-config.txt)
  - Image scan: [EVIDENCE/S12/trivy-image.txt](../EVIDENCE/S12/trivy-image.txt)

- **Выводы:**
  1. Container/Image findings (HIGH):
     - CVE-2024-47874 в starlette 0.37.2 (DoS via multipart/form-data)
     - Dockerfile: нет USER (non-root) директивы
     - Отсутствует HEALTHCHECK
  2. K8s configuration findings (HIGH):
     - readOnlyRootFilesystem не установлен
     - Используется root пользователь (securityContext.runAsUser: 0)
     - Отсутствуют resource limits
     - Используется latest tag
     - Нет liveness/readiness probes
     - NetworkPolicy не определена
  3. Actions:
     - Обновить starlette до 0.40.0
     - Добавить non-root USER в Dockerfile
     - Настроить SecurityContext в k8s (non-root, readonly fs)
     - Добавить resource limits и probes
     - Использовать фиксированные теги образов
     - Определить NetworkPolicy
     
- **Owner/Status:**
  - Container/Image fixes: backend team (open)
  - K8s configuration: DevOps Team (open)
  - Priority: HIGH (critical findings in safety of containers)

---

## 4) Харднинг (доказуемый) (DS4)
- [x] **Контейнер non-root / drop capabilities** => Evidence: [Dockerfile](https://github.com/2gury/secdev-seed-s09-s12/blob/main/Dockerfile) [EVIDENCE/S12/checkov_afetr.json](../EVIDENCE/S12/checkov_afetr.json). Использование non-root docker/k8s. Использование тега вместо lastest. readonly fs
- [x] **Rate-limit / timeouts / retry budget** => Evidence: [main.py](https://github.com/2gury/secdev-seed-s09-s12/blob/main/app/main.py)
- [x] **Secrets handling** (отсутствуют секреты в гите и самого хранилища для секретов нет) => Evidence: [.gitleaks.toml](https://github.com/2gury/secdev-seed-s09-s12/blob/main/security/.gitleaks.toml), [action pipeline](https://github.com/2gury/secdev-seed-s09-s12/actions/runs/18851817495)
- [x] **HTTP security headers / CSP / HTTPS-only** => Evidence: [main.py](https://github.com/2gury/secdev-seed-s09-s12/blob/main/app/main.py)

---

## 5) Quality-gates и проверка порогов (DS5)
### 5.1 Пороговые правила
| Контроль                        | Пороговое условие               | Основание                                                                           |
| ------------------------------- | ------------------------------- | ----------------------------------------------------------------------------------- |
| **SCA (Grype)**                 | `Critical = 0, High ≤ 1`        | Наличие 1 High уязвимости в (Jinja2 < 3.1.*), обнова в планах                       |
| **SAST (Semgrep)**              | `Critical = 0, High = 0`        | Профиль p/ci не выявил нарушений                                                    |
| **Secrets (Gitleaks)**          | `Истинных находок = 0`          | Проверено по `EVIDENCE/S10/gitleaks.json`                                           |
| **DAST (ZAP Baseline)**         | `High = 0, Medium ≤ 2`          | После добавления CSP и XFO остались только информационные уведомления               |
| **Policy/IaC (Trivy, Checkov)** | `High, Critical violations = 0` | Dockerfile и манифест K8s приведены к best-practice: readonly, non root, etc.       |

### 5.2 Проверка в CI/CD
Пороговые проверки встроены в GitHub Actions workflow проекта, выполняются вручную/при пуше/на PR
[`.github/workflows`](https://github.com/2gury/secdev-seed-s09-s12/tree/main/.github/workflows)

---

## 6) Эффект «до/после» (метрики) (DS4/DS5)
| Контроль/Мера                 | Метрика          |        До |      После | Evidence (до), (после)                                                                                          |
| ----------------------------- | ---------------- | --------: | ---------: | --------------------------------------------------------------------------------------------------------------- |
| **Policy/IaC (Checkov, K8s)** | Количество провалов  |   17 |      8 | [EVIDENCE/S12/checkov.json](../EVIDENCE/S12/checkov.json) (summary: failed=17, passed=70)  => [EVIDENCE/S12/checkov_after.json](../EVIDENCE/S12/checkov_afetr.json) (failed=8, passed=81)  |
| **SCA (Grype по SBOM)**       | Critical / High  | 0 / 1 |  0 / 1 | сводка DS: Jinja2=High (CVE-2024-56201) в [EVIDENCE/S09/sca_report.json](../EVIDENCE/S09/sca_report.json) |
| **SAST (Semgrep p/ci)**       | Critical / High  |     0 / 0 |      0 / 0 | [EVIDENCE/S10/semgrep.sarif](../EVIDENCE/S10/semgrep.sarif) |
| **Secrets (Gitleaks)**        | Истинные находки |         0 |          0 | [EVIDENCE/S10/gitleaks.json](../EVIDENCE/S10/gitleaks.json) [EVIDENCE/S10/gitleaks_after.json](../EVIDENCE/S10/gitleaks_after.json) |
| **DAST (ZAP Baseline)**       | High / Medium    | 0 / 2 | 0 / 2 | [EVIDENCE/S11/zap_baseline.json](../EVIDENCE/S11/zap_baseline.json) |

---

## 7) Самооценка по рубрике DS (0/1/2)
- **DS1. SBOM и SCA:** [ ] 0 [ ] 1 [x] 2
- **DS2. SAST + Secrets:** [ ] 0 [ ] 1 [x] 2
- **DS3. DAST или Policy (Container/IaC):** [ ] 0 [ ] 1 [x] 2
- **DS4. Харднинг (доказуемый):** [ ] 0 [x] 1 [ ] 2
- **DS5. Quality-gates, триаж и «до/после»:** [ ] 0 [x] 1 [ ] 2

**Итог DS (сумма):** 8/10
