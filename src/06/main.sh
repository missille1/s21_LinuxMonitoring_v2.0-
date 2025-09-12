#!/bin/bash
source ./util.sh

check_no_args "$@"
check_logs
check_goaccess

main() {
goaccess nginx_access_*.log \
  --log-format=COMBINED \
  --date-format=%d/%b/%Y \
  --time-format=%T \
    -o ./goaccess.html

}

main "$@"

#  