#!/bin/bash
source ./util.sh

check_no_args "$@"
check_logs
check_goaccess

# Останавливаем предыдущие процессы
pkill darkhttpd 2>/dev/null
pkill goaccess 2>/dev/null

main() {
	goaccess nginx_access_*.log \
        --log-format=COMBINED \
		-o report.html 

    darkhttpd . --port 9191 --index report.html > /dev/null 2>&1 &
    echo "Веб-сервер запущен на порту 9191"

    goaccess nginx_access_*.log \
        --log-format=COMBINED 
}

main "$@"