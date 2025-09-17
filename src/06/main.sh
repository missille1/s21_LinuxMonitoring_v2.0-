#!/bin/bash
source ./util.sh

check_no_args "$@"
check_logs
check_goaccess

pkill darkhttpd
pkill goaccess

main() {
# Запускаем веб-сервер (обслуживает текущую директорию)
darkhttpd . --port 9191 &> /dev/null &

goaccess nginx_access_*.log \
    --log-format=COMBINED \
    --real-time-html \
    -o report.html
echo "Веб-интерфейс: http://192.168.56.107:9191"
echo "HTML файл: report.html"
}

main "$@"
