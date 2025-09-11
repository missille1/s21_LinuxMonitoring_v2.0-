#!/bin/bash

run() {
	out_dir="report_$(date +%H%M%S)"
	mkdir -p -- "$out_dir"

	for f in "${files[@]}"; do
		case "$MODE" in
		1)
			out="$out_dir/sorted_by_status.log"
			# статус — 9-е поле
			awk '{ print $9 "\t" $0 }' "$f" | sort -n -k1,1 | cut -f2- >"$out"
			;;
		2)
			out="$out_dir/unique_ips.txt"
			awk '{ print $1 }' "$f" | sort -u >"$out"
			;;
		3)
			out="$out_dir/error_requests.log"
			awk '$9 ~ /^[45][0-9][0-9]$/ { print }' "$f" >"$out"
			;;
		4)
			out="$out_dir/error_unique_ips.txt"
			awk '$9 ~ /^[45][0-9][0-9]$/ { print $1 }' "$f" | sort -u >"$out"
			;;
		esac
		lines=0
		[ -s "$out" ] && lines=$(wc -l <"$out")
		echo "$f $out ($lines строк)"
	done
}
