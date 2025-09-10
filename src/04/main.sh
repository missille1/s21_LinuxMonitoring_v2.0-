#!/bin/bash

source ./util.sh
source ./core.sh

# Месяцы/даты в логах англоязычные
LC_ALL=C
LC_TIME=C

check_no_args "$@"

for offset in 0 1 2 3 4; do
	generate_log_file "$offset"
done
