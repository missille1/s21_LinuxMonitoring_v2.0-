#!/bin/bash

source core.sh

# Проверка аргументов
if [ $# -gt 0 ]; then
    echo "Ошибка: Скрипт запускается без аргументов" >&2
    echo "Использование: $0" >&2
    exit 1
fi

iterval=3                                      

main_loop() {
    ensure_dir
    trap 'exit 0' INT TERM
    while :; do
        write_metrics_once
        sleep "$iterval"
    done
}

main_loop