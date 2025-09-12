#!/bin/bash

die() { printf "Ошибка: %s\n" "$*" >&2; exit 1; }

# Скрипт запускается БЕЗ аргументов
check_no_args() {
  if [ "$#" -ne 0 ]; then
    die "скрипт не принимает аргументы. Запускайте: ./main.sh"
  fi
}

check_logs() {
	if ! ls nginx_access_*.log >/dev/null 2>&1; then
		echo "Логи по маске 'nginx_access_*.log' не найдены в $(pwd)"
		exit 1
	fi
}

check_goaccess() {
	command -v goaccess >/dev/null || { echo "goaccess не установлен"; exit 1; }
}
