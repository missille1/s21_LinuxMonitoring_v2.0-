#!/usr/bin/env bash
# Генератор 5-ти nginx access логов (combined format).
# Каждый файл — один день, записи (100..1000) с временем по возрастанию.
#
# Справка по кодам ответов, использованным ниже:
# 200 OK                  — успешный запрос
# 201 Created             — ресурс создан (обычно после POST)
# 400 Bad Request         — некорректный запрос клиента
# 401 Unauthorized        — требуется аутентификация
# 403 Forbidden           — доступ запрещён
# 404 Not Found           — ресурс не найден
# 500 Internal Server Error — внутренняя ошибка сервера
# 501 Not Implemented     — метод/функция не реализованы
# 502 Bad Gateway         — некорректный ответ от upstream
# 503 Service Unavailable — сервис временно недоступен/перегружен

set -euo pipefail

# Месяцы/даты в логах должны быть англоязычными (Jan/Feb/...):
LC_ALL=C
LC_TIME=C

# -------- утилиты случайностей --------
rand_int() { # rand_int MIN MAX (включительно)
  local lo="$1" hi="$2"
  # $RANDOM (0..32767) — достаточно для наших диапазонов
  echo $(( lo + (RANDOM % (hi - lo + 1)) ))
}

rand_pick() { # rand_pick item1 item2 ...
  local arr=("$@")
  local idx
  idx=$(rand_int 0 $((${#arr[@]} - 1)))
  printf '%s' "${arr[$idx]}"
}

# -------- справочные массивы --------
STATUSES=(200 201 400 401 403 404 500 501 502 503)
METHODS=(GET POST PUT PATCH DELETE)
HTTP_VERSIONS=("HTTP/1.0" "HTTP/1.1" "HTTP/2.0")

# Набор «правдоподобных» User-Agent
UAS=(
  "Mozilla/5.0 (X11; Linux x86_64; rv:117.0) Gecko/20100101 Firefox/117.0"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
  "Opera/9.80 (Windows NT 6.1; WOW64) Presto/2.12.388 Version/12.18"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Safari/605.1.15"
  "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0)"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edg/124.0"
  "Googlebot/2.1 (+http://www.google.com/bot.html)"
  "curl/7.88.1"
  "Wget/1.21.3 (linux-gnu)"
  "python-requests/2.31.0"
)

# Базовые домены/пути под URL и рефереры
DOMAINS=(example.com shop.example.com cdn.example.com static.example.com api.example.com)
PATHS=(
  "/" "/index.html" "/about" "/contact"
  "/products" "/products/%d" "/products/%d/reviews"
  "/api/v1/users" "/api/v1/users/%d" "/api/v1/orders" "/api/v1/orders/%d"
  "/search?q=term%d" "/static/js/app.%d.js" "/static/css/styles.%d.css"
  "/img/banner%d.jpg" "/download/file%d.bin"
)

# -------- генераторы полей --------
gen_ip() { # 1..254 в каждом октете → валидные адреса
  printf '%d.%d.%d.%d' \
    "$(rand_int 1 254)" "$(rand_int 1 254)" \
    "$(rand_int 1 254)" "$(rand_int 1 254)"
}

gen_path() {
  local raw sel n
  sel=$(rand_pick "${PATHS[@]}")
  # подставим цифры, если есть %d
  n=$(rand_int 1 9999)
  printf "$sel" "$n" 2>/dev/null || printf '%s' "$sel"
}

gen_host() {
  printf '%s' "$(rand_pick "${DOMAINS[@]}")"
}

gen_referer() {
  # 60% — нет реферера, иначе — ссылка с тем же набором доменов/путей
  if (( $(rand_int 1 100) <= 60 )); then
    printf '-'
  else
    printf 'https://%s%s' "$(gen_host)" "$(gen_path)"
  fi
}

bytes_for_status() {
  case "$1" in
    200|201)            rand_int 512 524288 ;;
    400|401|403|404)    rand_int 0 8192     ;;
    500|501|502|503)    rand_int 0 4096     ;;
    *)                  rand_int 0 32768    ;;
  esac
}

# Сгенерировать N уникальных секунд в пределах суток (0..86399), отсортировать.
# Использует shuf при наличии (быстро), иначе — bash-словарь (чуть медленнее).
gen_sorted_seconds() {
  local n="$1"
  if command -v shuf >/dev/null 2>&1; then
    shuf -i 0-86399 -n "$n" | sort -n
  else
    # Без shuf: собираем в ассоц. массив, затем сортируем
    declare -A S=()
    local x
    while (( ${#S[@]} < n )); do
      x=$(rand_int 0 86399)
      S["$x"]=1
    done
    printf '%s\n' "${!S[@]}" | sort -n
  fi
}

# -------- основной цикл по 5 дням --------
for offset in 0 1 2 3 4; do
  # День: сегодня-offset
  day_start_epoch=$(date -d "today -${offset} day 00:00:00" +%s)
  day_tag=$(date -d "@$day_start_epoch" +%Y%m%d)   # для имени файла
  tz_offset=$(date -d "@$day_start_epoch" +%z)     # часовой пояс в момент дня
  out="nginx_access_${day_tag}.log"

  # Случайное число записей на день
  rows=$(rand_int 100 1000)

  # Сгенерируем строго возрастающие метки времени в рамках суток
  mapfile -t SECS < <(gen_sorted_seconds "$rows")

  : > "$out"
  for s in "${SECS[@]}"; do
    t=$(( day_start_epoch + s ))
    # Время в формате nginx time_local: [10/Oct/2000:13:55:36 +0300]
    when=$(date -d "@$t" "+%d/%b/%Y:%H:%M:%S ${tz_offset}")

    ip=$(gen_ip)
    method=$(rand_pick "${METHODS[@]}")
    path=$(gen_path)
    host=$(gen_host)
    ver=$(rand_pick "${HTTP_VERSIONS[@]}")
    status=$(rand_pick "${STATUSES[@]}")
    bytes=$(bytes_for_status "$status")
    referer=$(gen_referer)
    ua=$(rand_pick "${UAS[@]}")

    # Combined формат:
    # $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"
    printf '%s - - [%s] "%s %s %s" %d %d "%s" "%s"\n' \
      "$ip" "$when" "$method" "$path" "$ver" "$status" "$bytes" "$referer" "$ua" \
      >> "$out"
  done

  echo "OK: сгенерирован $out (${#SECS[@]} записей)"
done
