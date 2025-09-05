#!/bin/bash

seq_for_index() {
	letters="$1"
	idx="$2"
	minlen=4 # для 01 minlen=4
	L=${#letters}

	if [ "$L" -gt "$minlen" ]; then
		target_base="$L"
	else
		target_base="$minlen"
	fi

	target=$((target_base + idx - 1))
	extra=$((target - L))
	# [ "$extra" -lt 0 ] && extra=0

	q=$((extra / L)) # добавить каждой букве
	r=$((extra % L)) # первым r буквам ещё по 1

	out=""
	p=1
	while [ "$p" -le "$L" ]; do
		ch=$(printf "%s" "$letters" | cut -c"$p")
		cnt=$((1 + q))
		[ "$p" -le "$r" ] && cnt=$((cnt + 1))
		k=1
		while [ "$k" -le "$cnt" ]; do
			out="${out}${ch}"
			k=$((k + 1))
		done
		p=$((p + 1))
	done

	printf "%s" "$out"
}

seq_for_index azaz 3