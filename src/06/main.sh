#!/bin/bash
source ./util.sh

check_no_args "$@"
check_logs

main() {
goaccess nginx_access_*.log \
  --log-format=COMBINED \
  --date-format=%d/%b/%Y \
  --time-format=%T \
  --real-time-html \
  --addr=0.0.0.0 \
  --port=8080 \
    -o ./goaccess.html

}

main "$@"
