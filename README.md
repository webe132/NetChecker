
# NetChecker

Проверяет доступ к глобальному интернету и рунету. Показывает статус и задержку для ключевых сервисов.

## Что проверяет

**Глобальный интернет** — Google DNS, Cloudflare DNS, google.com, cloudflare.com  
**Рунет** — Яндекс, ВКонтакте, Mail.ru, Госуслуги  
**Блокировки РКН** — Twitter/X, Instagram, Facebook, LinkedIn, Meduza, BBC

## Установка

### Termux (Android)

```bash
pkg install curl
curl -sL "https://raw.githubusercontent.com/webe132/NetChecker/main/netchecker.sh" -o "$PREFIX/bin/netcheck"
chmod +x "$PREFIX/bin/netcheck"
```

### Windows — Git Bash

Требуется [Git for Windows](https://git-scm.com/download/win). В **Git Bash**:

```bash
mkdir -p ~/.local/bin && curl -sL "https://raw.githubusercontent.com/webe132/NetChecker/main/netchecker.sh" -o ~/.local/bin/netcheck && chmod +x ~/.local/bin/netcheck
```

> **Важно:** эту команду нужно запускать именно в Git Bash, а не в PowerShell или CMD.

### Linux / macOS

```bash
mkdir -p ~/.local/bin && curl -sL "https://raw.githubusercontent.com/webe132/NetChecker/main/netchecker.sh" -o ~/.local/bin/netcheck && chmod +x ~/.local/bin/netcheck
```

## Запуск

```bash
netcheck
# или
netchecker
```

После установки на Windows перезапустите терминал.

## Использование

```bash
# Стандартная проверка (интернет + рунет + блокировки РКН)
netcheck

# Проверка конкретных сайтов
netcheck telegram.org
netcheck site1.com site2.com site3.com
netcheck https://example.com 8.8.8.8
```

## Зависимости

| Платформа | Зависимости |
|-----------|-------------|
| Termux    | `pkg install curl` |
| Linux     | `curl` (обычно предустановлен) |
| macOS     | `curl` (предустановлен) |
| Windows   | [Git for Windows](https://git-scm.com/download/win) |

Ping на IP-адреса (DNS-серверы) проверяется через TCP-соединение на порт 53 — работает без root и без отдельной утилиты ping.

## Пример вывода

```
  NetChecker  v1.0.0
  ──────────────────────────────────────

  Глобальный интернет
  ──────────────────────────────────────
    ✓  Google DNS               12 ms
    ✓  Cloudflare DNS            8 ms
    ✓  google.com               45 ms
    ✓  cloudflare.com           38 ms

  Рунет
  ──────────────────────────────────────
    ✓  Яндекс                   23 ms
    ✓  ВКонтакте                31 ms
    ✗  Госуслуги           недоступен
    ✓  Mail.ru                  28 ms

  Блокировки РКН
  ──────────────────────────────────────
    ✗  Twitter / X         недоступен
    ✗  Instagram           недоступен
    ✗  Facebook            недоступен
    ✓  LinkedIn                 55 ms
    ✗  Meduza               недоступен
    ✗  BBC Русская служба   недоступен

  ──────────────────────────────────────
  Итог:
    Интернет        ✓ доступен    (4/4)
    Рунет           ~ частично    (3/4)
    Блокировки РКН  частично      (1/6)
```

## Настройка целей

Списки проверяемых ресурсов находятся в начале скрипта (`GLOBAL_TARGETS`, `RUNET_TARGETS`, `BLOCKED_TARGETS`). Формат: `"Имя|url_или_ip"`.

## Дисклеймер

Инструмент предназначен исключительно для диагностики сетевого подключения. Не помогает обходить блокировки и не предоставляет доступ к заблокированным ресурсам.

Все упомянутые названия (Google, Cloudflare, Яндекс, ВКонтакте и др.) являются торговыми марками своих владельцев. Проект никак не связан с этими компаниями и не претендует на аффилированность с ними — их адреса используются исключительно как общедоступные точки проверки подключения.

Meta Platforms Inc. (Facebook, Instagram) признана экстремистской организацией и запрещена на территории Российской Федерации. Их адреса используются в скрипте исключительно как технические точки проверки сетевой доступности.

Используйте в соответствии с законодательством вашей страны.

## Лицензия

[MIT](LICENSE)
