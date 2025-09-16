#!/bin/bash

die() {
	printf "Ошибка: %s\n" "$*" >&2
	exit 2
}

# проверки
ensure_readable_file() {
	f="$1"
	[ -f "$f" ] && [ -r "$f" ] || die "лог недоступен: $f"
}

norm_time_min() {
	date -d "$1" '+%Y-%m-%d %H:%M' 2>/dev/null
}

time_to_epoch() {
	date -d "$1" '+%s' 2>/dev/null
}

require_datetime_with_minutes() {
	local s="$1"
	# Явная проверка наличия и пробела и двоеточия
	if [[ "$s" != *" "* ]] || [[ "$s" != *:* ]]; then
		return 1
	fi
	# Проверяем что после пробела ровно 5 символов (HH:MM)
	local time_part="${s#* }"
	if [[ "${#time_part}" -ne 5 ]] || [[ ! "$time_part" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
		return 1
	fi
	# Проверяем что дата может быть распаршена
	if ! date -d "$s" "+%Y-%m-%d %H:%M" >/dev/null 2>&1; then
		return 1
	fi
	printf '%s' "$s"
	return 0
}
