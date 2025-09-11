#!/bin/bash

usage() {
	echo "Используются только параметры: $0 1|2|3|4"
	echo "  1 — все записи, отсортированные по коду ответа"
	echo "  2 — все уникальные IP"
	echo "  3 — все записи с ошибками (4xx/5xx)"
	echo "  4 — все уникальные IP среди ошибочных запросов"
	exit 1
}

check_args() {
	[ "$#" -eq 1 ] || usage
	case "$1" in 1 | 2 | 3 | 4) MODE="$1" ;; *) usage ;; esac
}

check_logs() {
	if ! ls nginx_access_*.log >/dev/null 2>&1; then
		echo "Логи по маске 'nginx_access_*.log' не найдены в $(pwd)"
		exit 1
	fi
}

