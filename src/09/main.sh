#!/bin/bash

source core.sh

main_loop() {
	ensure_dir
	trap 'exit 0' INT TERM
	while :; do
		write_metrics_once
		sleep 3
	done
}

check "$@"
main_loop

# http://192.168.56.107:9110/metrics
# promtool check config /etc/prometheus/prometheus.yml
