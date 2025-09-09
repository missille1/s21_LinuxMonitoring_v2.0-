#!/bin/bash

_body_re_from_letters() {
	s="$1"
	out=""
	i=1
	while [ "$i" -le "${#s}" ]; do
		ch=$(printf "%s" "$s" | cut -c"$i")
		out="${out}${ch}+"
		i=$((i + 1))
	done
	printf "%s\n" "$out"
} 

body_re=$(_body_re_from_letters az)

echo "______________"

mask=az_280909
letters="${mask%%_*}"
dtag="${mask##*_}"

d="az/lol/"

bn="${d##*/}"

echo $letters $dtag $bn "op" $body_re

dir_re="^${body_re}_${dtag}$"

echo $dir_re

echo '________________====='

[[ "$bn" =~ $dir_re ]]




