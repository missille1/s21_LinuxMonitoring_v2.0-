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
  # Проверяем только наличие компонента времени (не диапазон часов/минут).
  if [[ "$s" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}$ ]]; then
    return 0
  fi
  return 1
}

