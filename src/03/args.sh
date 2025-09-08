#!/bin/bash

# глобальные переменный после парсинга
ARG_MODE=0
ARG_LOG=""
ARG_T_START=""
ARG_T_END=0
ARG_MASK=""

ensure_readable_file() {
	f="$1"
	[ -f "$f" ] && [ -r "$f" ] || { printf "Ошибка: лог не может быть прочитан: %s\n" "$f" >&2; return 1; }
}

parse_args() {
	[ "$#" -ge 1 ] || { printf "Используется: %s <mode>\n" "$0" >&2; return 1; }
	m="$1"; shift || true # на месте $1 ставим наш путь до лога, вместо 1. True гасит ошибку exit 0

	case "$m" in
		1)
		# путь к логу
		[ "$#" -ge 1 ] || { printf "Ошибка: должен быть 1 путь до лога\n" >&2; return 1; }
		ARG_MODE=1
		ARG_LOG="$1"
		ensure_readable_file "$ARG_LOG" || return 1
		;; 
		2) 
		# время начала и конца создания файлов
		ARG_MODE=2
		ARG_T_START="${1:-}"
		ARG_T_END="${2:-}"
		;;
		3) 
		# удаление по маске
		ARG_MODE=3
		ARG_MASK="${1:-}"
		;;
		*)
		printf "Ошибка: параметр должен быть 1, 2 или 3\n" >&2; return 1;;
	esac

	printf "[ok] параметр=%s\n" "$ARG_MODE"
}