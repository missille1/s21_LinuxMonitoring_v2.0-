#!/bin/bash

source ./util.sh
source ./args.sh
source ./core.sh

set -u # если есть неиспользуемые переменные падаем

parse_args "$@" || exit 2
print_info
run_core

# test for memory
# MIN_FREE_KB=6103575 ./main.sh az az.az 1Mb ; echo $?
