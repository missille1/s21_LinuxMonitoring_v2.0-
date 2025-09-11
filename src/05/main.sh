#!/bin/bash

source ./util.sh
source ./core.sh

check_args "$@"
check_logs
run


echo "Готово. Каталог отчёта: $out_dir"
