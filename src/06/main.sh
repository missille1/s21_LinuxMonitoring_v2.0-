#!/bin/bash
source ./util.sh

check_no_args "$@"
check_logs
check_goaccess

main() {
goaccess nginx_access_*.log \
    --log-format=COMBINED \
    --real-time-html \
    --addr=127.0.0.1 \
    --port=7890 \
    --daemonize
  echo "[INFO] GoAccess запущен."
}

main "$@"

#  