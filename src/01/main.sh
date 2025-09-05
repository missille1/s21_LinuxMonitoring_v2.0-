#!/bin/bash

source ./util.sh
source ./args.sh
source ./core.sh

parse_args "$@" || exit 2
print_info
run_core

# test for memory
# MIN_FREE_KB=6103575 ./main.sh /tmp/xtest1 4 az 5 az.az 3kb ; echo $?
