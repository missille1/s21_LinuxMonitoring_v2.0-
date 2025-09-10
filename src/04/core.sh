#!/bin/bash

# Справка по кодам ответов:
# 200 OK                  — успешный запрос
# 201 Created             — ресурс создан (обычно после POST)
# 400 Bad Request         — некорректный запрос клиента
# 401 Unauthorized        — требуется аутентификация
# 403 Forbidden           — доступ запрещён
# 404 Not Found           — ресурс не найден
# 500 Internal Server Error — внутренняя ошибка сервера
# 501 Not Implemented     — метод/функция не реализованы
# 502 Bad Gateway         — некорректный ответ
# 503 Service Unavailable — сервис временно недоступен

# GET — получение ресурса
# POST — создание ресурса
# PUT — обновление ресурса
# PATCH — обновление ресурса
# DELETE — удаление ресурса

# коды методы
STATUSES=(200 201 400 401 403 404 500 501 502 503)
METHODS=(GET POST PUT PATCH DELETE)
HTTP_VERSIONS=("HTTP/1.0" "HTTP/2.0")

# Набор User-Agent
UAS=(
	"Mozilla (Linux x86_64)  Firefox/142.0"
	"Chrome (Windows; x64) Chrome/140.0"
	"Opera (Linux x86_64) Opera/104.0"
	"Safari (Macintosh) Safari/15.6.1"
	"Internet Explorer (Windows; x64)"
	"Microsoft Edge (Windows; x64)"
	"YandexBot/3.0; (+http://yandex.com/bots)"
	"curl/8.16.0"
	"python-requests/2.32.5"
)

# Базовые домены/пути под URL и рефереры
DOMAINS=(example.com example.com)
PATHS=("/" "/about" "/contact")

# ip
gen_ip() {
	printf '%d.%d.%d.%d' \
		"$(rand_int 1 254)" "$(rand_int 1 254)" \
		"$(rand_int 1 254)" "$(rand_int 1 254)"
}

gen_path() {
	sel=$(rand_pick "${PATHS[@]}")
	printf '%s' "$sel"
}

gen_host() {
	printf '%s' "$(rand_pick "${DOMAINS[@]}")"
}

gen_referer() {
	printf 'https://%s%s' "$(gen_host)" "$(gen_path)"
}

bytes_for_status() {
	case "$1" in
	200 | 201) rand_int 1000 2000 ;;
	400 | 401 | 403 | 404) rand_int 0 1000 ;;
	500 | 501 | 502 | 503) rand_int 0 500 ;;
		# *)                  rand_int 0 32768    ;;
	esac
}

# Сгенерировать N уникальных секунд в пределах суток (0..86400), отсортировать.
gen_sorted_seconds() {
	local n="$1"
	shuf -i 0-86400 -n "$n" | sort -n
	printf '%s\n' "${!S[@]}" # выводим ключи массива
}

generate_log_file() {
	# День: сегодня-offset
	day_start_epoch=$(date -d "today -${offset} day 00:00:00" +%s)
	day_tag=$(date -d "@$day_start_epoch" +%Y%m%d) # для имени файла
	tz_offset=$(date -d "@$day_start_epoch" +%z)   # часовой пояс в момент дня
	out="nginx_access_${day_tag}.log"

	# Случайное число записей на день
	rows=$(rand_int 100 1000)

	# печатаем время
	# mapfile чтение в массив SECS -t удаляем \n, < < перевод вывода функции в массив
	mapfile -t SECS < <(gen_sorted_seconds "$rows")

	# Очистка файла при повтором запуске
	: >"$out"
	for s in "${SECS[@]}"; do
		t=$((day_start_epoch + s))
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
			>>"$out"
	done

	echo "сгенерирован $out (${#SECS[@]} записей)"
}
