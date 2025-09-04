#!/bin/bash

bases="/home/user
/etc
/var/log"

echo "$bases" | while read base_path; do
    echo "Обрабатываю: $base_path"
    ls -la "$base_path" | head -3  # пример обработки
done