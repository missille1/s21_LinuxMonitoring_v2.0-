#!/bin/bash

z=1
while [ $z -le 5 ]; do
	rand_int() { # rand_int MIN MAX (включительно)
	local lo="$1" hi="$2"
	# $RANDOM (0..32767) — достаточно для наших диапазонов
	echo $(( lo + (RANDOM % (hi - lo + 1)) ))
	}

	gen_sorted_seconds() {
		local n="$1"
		shuf -i 0-86400 -n "$n" | sort -n
		printf '%s\n' "${!S[@]}" # выводим ключи массива
	}

	# -------- основной цикл по 5 дням --------
	rows=$(rand_int 100 1000)
	# mapfile чтение в массив SECS -t удаляем \n, < < перевод вывода функции в массив
	mapfile -t SECS < <(gen_sorted_seconds "$rows")
	printf '%s' "${SECS[a]:0:10}"
	echo '_____'
	z=$((z+1))
done