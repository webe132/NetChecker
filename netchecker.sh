#!/usr/bin/env bash

# ──────────────────────────────────────────────────────────
#  NetChecker — проверка доступа к интернету и рунету
#  https://github.com/webe132/NetChecker
# ──────────────────────────────────────────────────────────

VERSION="1.0.0"

# ANSI цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

if [ ! -t 1 ] || [ "${NO_COLOR:-}" = "1" ]; then
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; DIM=''; NC=''
fi

# ── Цели проверки: "Имя|url_или_ip" ───────────────────────

GLOBAL_TARGETS=(
    "Google DNS|8.8.8.8"
    "Cloudflare DNS|1.1.1.1"
    "google.com|https://www.google.com"
    "cloudflare.com|https://www.cloudflare.com"
)

RUNET_TARGETS=(
    "Яндекс|https://yandex.ru"
    "ВКонтакте|https://vk.com"
    "Mail.ru|https://mail.ru"
    "Госуслуги|https://gosuslugi.ru"
)

# Сайты, заблокированные РКН (зелёный = доступен через VPN, красный = заблокирован)
BLOCKED_TARGETS=(
    "Twitter / X|https://twitter.com"
    "Instagram|https://www.instagram.com"
    "Facebook|https://www.facebook.com"
    "LinkedIn|https://www.linkedin.com"
    "Meduza|https://meduza.io"
    "BBC Русская служба|https://www.bbc.com/russian"
)

# Счётчики секций
G_OK=0; G_TOTAL=0
R_OK=0; R_TOTAL=0
B_OK=0; B_TOTAL=0
C_OK=0; C_TOTAL=0

# Временная папка для результатов параллельных проверок
NC_TMPDIR=""

cleanup() {
    [ -n "$NC_TMPDIR" ] && rm -rf "$NC_TMPDIR"
}
trap cleanup EXIT

# ── Проверки ───────────────────────────────────────────────

# Нормализует десятичный разделитель (запятая → точка) для awk
_dots() { printf '%s' "$1" | tr ',' '.'; }

check_http() {
    local url="$1"
    local out
    out=$(LC_NUMERIC=C curl -s -o /dev/null \
        -w "%{http_code}|%{time_total}" \
        --connect-timeout 5 \
        --max-time 8 \
        -L \
        "$url" 2>/dev/null) || { echo "FAIL|0"; return; }

    local code="${out%%|*}"
    local secs
    secs=$(_dots "${out##*|}")
    local ms
    ms=$(LC_NUMERIC=C awk "BEGIN{printf \"%d\", $secs * 1000}")

    [[ "$code" =~ ^[23] ]] && echo "OK|$ms" || echo "FAIL|0"
}

check_ping() {
    local host="$1"
    local ms=""

    # Пробуем ping (на Termux недоступен без pkg install inetutils)
    if command -v ping &>/dev/null; then
        local out
        if [[ "${OSTYPE:-}" == "msys" || "${OSTYPE:-}" == "cygwin" ]]; then
            out=$(ping -n 1 "$host" 2>/dev/null) || true
            ms=$(printf '%s\n' "$out" | grep -oE '[0-9]+ms' | grep -oE '[0-9]+' | head -1)
        elif [[ "${OSTYPE:-}" == "darwin"* ]]; then
            out=$(ping -c 1 -t 3 "$host" 2>/dev/null) || true
            ms=$(printf '%s\n' "$out" | grep -oE 'time=[0-9.]+' | cut -d= -f2 | cut -d. -f1)
        else
            out=$(ping -c 1 -W 3 "$host" 2>/dev/null) || true
            ms=$(printf '%s\n' "$out" | grep -oE 'time=[0-9.]+' | cut -d= -f2 | cut -d. -f1)
        fi
    fi

    # Fallback: TCP-соединение на порт 53 через curl (работает везде, в т.ч. Termux)
    if [ -z "$ms" ] || [ "$ms" = "0" ]; then
        local secs
        secs=$(LC_NUMERIC=C curl -s -o /dev/null \
            -w "%{time_connect}" \
            --connect-timeout 5 \
            "http://$host:53" 2>/dev/null) || true
        secs=$(_dots "$secs")
        if [ -n "$secs" ]; then
            ms=$(LC_NUMERIC=C awk "BEGIN{v=int($secs*1000); if(v>0) print v}" 2>/dev/null)
        fi
    fi

    [ -n "$ms" ] && echo "OK|$ms" || echo "FAIL|0"
}

# Запускается в фоне, пишет результат в файл
run_check_bg() {
    local idx="$1"
    local name="$2"
    local target="$3"
    local result

    if [[ "$target" =~ ^https?:// ]]; then
        result=$(check_http "$target")
    else
        result=$(check_ping "$target")
    fi

    printf '%s|%s\n' "$name" "$result" > "$NC_TMPDIR/$idx"
}

# ── Вывод ──────────────────────────────────────────────────

print_row() {
    local name="$1" status="$2" ms="$3"
    if [ "$status" = "OK" ]; then
        if [ "$ms" -gt 800 ]; then
            printf "    ${GREEN}✓${NC}  %-26s ${YELLOW}%4d ms${NC}\n" "$name" "$ms"
        else
            printf "    ${GREEN}✓${NC}  %-26s ${DIM}%4d ms${NC}\n" "$name" "$ms"
        fi
    else
        printf "    ${RED}✗${NC}  %-26s ${RED}недоступен${NC}\n" "$name"
    fi
}

run_section() {
    local title="$1"
    local ok_var="$2"
    local total_var="$3"
    shift 3
    local entries=("$@")
    local count=${#entries[@]}
    local ok=0 total=0 i
    local pids=()

    printf "\n  ${BOLD}%s${NC}\n" "$title"
    printf "  ${DIM}──────────────────────────────────────${NC}\n"

    printf "  ${DIM}  проверяем %d узлов...${NC}" "$count"

    for i in "${!entries[@]}"; do
        local name="${entries[$i]%%|*}"
        local target="${entries[$i]##*|}"
        run_check_bg "$i" "$name" "$target" &
        pids+=($!)
    done

    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null || true
    done

    printf "\r\033[2K"

    for i in "${!entries[@]}"; do
        local line
        line=$(cat "$NC_TMPDIR/$i" 2>/dev/null) || continue
        rm -f "$NC_TMPDIR/$i"

        local name="${line%%|*}"
        local rest="${line#*|}"
        local status="${rest%%|*}"
        local ms="${rest##*|}"

        total=$((total + 1))
        [ "$status" = "OK" ] && ok=$((ok + 1))
        print_row "$name" "$status" "$ms"
    done

    eval "${ok_var}=${ok}"
    eval "${total_var}=${total}"
}

# ── Итог ───────────────────────────────────────────────────

print_verdict() {
    local ok=$1 total=$2
    if [ "$total" -eq 0 ]; then
        printf "${DIM}нет данных${NC}"
    elif [ "$ok" -eq "$total" ]; then
        printf "${GREEN}✓ доступен${NC}  ${DIM}(%d/%d)${NC}" "$ok" "$total"
    elif [ "$ok" -gt 0 ]; then
        printf "${YELLOW}~ частично${NC}  ${DIM}(%d/%d)${NC}" "$ok" "$total"
    else
        printf "${RED}✗ недоступен${NC}  ${DIM}(0/%d)${NC}" "$total"
    fi
}

print_blocked_verdict() {
    local ok=$1 total=$2
    if [ "$total" -eq 0 ]; then
        printf "${DIM}нет данных${NC}"
    elif [ "$ok" -eq 0 ]; then
        printf "${DIM}все заблокированы (норма без VPN)${NC}"
    elif [ "$ok" -eq "$total" ]; then
        printf "${CYAN}все доступны${NC}  ${DIM}(VPN включён?)${NC}"
    else
        printf "${YELLOW}~ частично доступны${NC}  ${DIM}(%d/%d)${NC}" "$ok" "$total"
    fi
}

# ── Точка входа ────────────────────────────────────────────

main() {
    NC_TMPDIR=$(mktemp -d)

    if ! command -v curl &>/dev/null; then
        printf "\n  ${RED}Ошибка: curl не найден${NC}\n"
        printf "  ${DIM}  Termux  : pkg install curl${NC}\n"
        printf "  ${DIM}  Linux   : sudo apt install curl${NC}\n"
        printf "  ${DIM}  Mac     : brew install curl${NC}\n"
        printf "  ${DIM}  Windows : установите Git for Windows${NC}\n\n"
        read -rp "  Нажмите Enter для выхода..."
        exit 1
    fi

    clear 2>/dev/null || printf "\033[2J\033[H"

    printf "\n  ${BOLD}${CYAN}NetChecker${NC}  ${DIM}v%s${NC}\n" "$VERSION"
    printf "  ${DIM}──────────────────────────────────────${NC}\n"

    if [ $# -gt 0 ]; then
        local custom_targets=()
        for arg in "$@"; do
            local display
            display=$(printf '%s' "$arg" | sed 's|^https\?://||' | sed 's|/.*||')

            if [[ "$arg" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                custom_targets+=("$display|$arg")
            elif [[ "$arg" =~ ^https?:// ]]; then
                custom_targets+=("$display|$arg")
            else
                custom_targets+=("$display|https://$arg")
            fi
        done

        run_section "Пользовательские цели" C_OK C_TOTAL "${custom_targets[@]}"

        printf "\n  ${DIM}──────────────────────────────────────${NC}\n"
        printf "  ${BOLD}Итог:${NC}\n"
        printf "    Результат  "; print_verdict "$C_OK" "$C_TOTAL"; printf "\n\n"
    else
        run_section "Глобальный интернет" G_OK G_TOTAL "${GLOBAL_TARGETS[@]}"
        run_section "Рунет"               R_OK R_TOTAL "${RUNET_TARGETS[@]}"
        run_section "Блокировки РКН"      B_OK B_TOTAL "${BLOCKED_TARGETS[@]}"

        printf "\n  ${DIM}──────────────────────────────────────${NC}\n"
        printf "  ${BOLD}Итог:${NC}\n"
        printf "    Интернет        "; print_verdict        "$G_OK" "$G_TOTAL"; printf "\n"
        printf "    Рунет           "; print_verdict        "$R_OK" "$R_TOTAL"; printf "\n"
        printf "    Блокировки РКН  "; print_blocked_verdict "$B_OK" "$B_TOTAL"; printf "\n\n"
    fi

    read -n 1 -s -r -p "  Нажмите любую клавишу для выхода..."
    printf "\n\n"
}

main "$@"
