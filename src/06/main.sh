#!/bin/bash
source ./util.sh

check_no_args "$@"
check_logs
check_goaccess

# Останавливаем предыдущие процессы
pkill darkhttpd 2>/dev/null
pkill goaccess 2>/dev/null

main() {
    # Запускаем веб-сервер в фоне
    darkhttpd . --port 9191 &> /dev/null &
    echo "Веб-сервер запущен на порту 9191"

    # Запускаем GoAccess в фоне с демонизацией
    goaccess nginx_access_*.log \
        --log-format=COMBINED \
        --real-time-html \
        -o report.html \
        --daemonize &
    
    echo "GoAccess запущен в фоновом режиме"
    echo "HTML файл: report.html"
    echo "Веб-интерфейс: http://192.168.56.107:9191/report.html"
    echo ""
    echo "Для остановки выполните: pkill darkhttpd && pkill goaccess"
    
    # Бесконечный цикл чтобы скрипт не завершался
    while true; do
        sleep 3600  # Спим 1 час, но можно прервать Ctrl+C
    done
}

main "$@"
