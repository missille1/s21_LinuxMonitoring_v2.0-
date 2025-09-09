#!/bin/bash

source ./util.sh
source ./args.sh
source ./core.sh

set -u

parse_args "$@" || exit 2

case "$ARG_MODE" in
1) delete_by_log "$ARG_LOG" ;;
2) delete_by_time "$ARG_T_START" "$ARG_T_END" ;;
3) delete_by_mask "$ARG_MASK" ;;
esac
