#!/bin/bash

die() {
	printf "Ошибка: %s\n" "$*" >&2 # перевод ошибок в stderr, * все аргументы в одну строку
	exit 2
}

print_info() {
	printf "[OK] parsed:\n"
	printf " letters_dirs   = %s\n" "$ARG_LETTERS_DIRS"
	printf " letters.ext    = %s.%s\n" "$ARG_FILE_LETTERS" "$ARG_FILE_EXT"
	printf " size.mb        = %s\n" "$ARG_SIZE_MB"
}

usage_short() {
	echo "Использование:"
	echo " ./main.sh <letters_dirs> <letters.ext> <sizeMb>"
	echo "Пример:"
	echo " ./main.sh az az.az 3Mb"
}

# целое число (0..)
is_unit() {
	echo "$1" | awk '/^[0-9]+$/ {exit 0} {exit 1}' # при успехе 0 при не удаче 1
}

# только [a-z]
ensure_letters() {
	echo "$1" | awk '/^[a-z]+$/ {exit 0} {exit 1}' || die "Доступны буквы [a-z]: '$1'"
}

# длина между min..max
ensure_len_range() {
	s="$1"
	min="$2"
	max="$3"
	len=${#s} # ${#var} возвращает длину значения
	[ "$len" -ge "$min" ] && [ "$len" -le "$max" ] || die "Длина должна быть $min..$max: '$s'"
}

# целое в [lo..hi]
ensure_unit_between() {
	v="$1"
	lo="$2"
	hi="$3"
	is_unit "$v" || die "Должно быть число, получили: '$v'"
	[ "$v" -ge "$lo" ] && [ "$v" -le "$hi" ] || die "Должно быть $lo..$hi, получили: $v"
}

# разбить letters.ext
split_letters_ext() {
	s="$1"
	# Ровно одна точка
    dots=$(printf "%s" "$s" | awk -F. '{print NF-1}')
    [ "$dots" -eq 1 ] || die "P3 должен быть в формате letters.ext, получили: '$s'"
	name=$(printf "%s" "$s" | cut -d. -f1)
	ext=$(printf "%s" "$s" | cut -d. -f2)
	# -n не пусто
	[ -n "$name" ] && [ -n "$ext" ] || die "P3 должно быть в формате az.az, получили: '$s'"
	echo "$name" "$ext"
}

# "NN" или "NNmb" -> "NN"
normalize_size_mb() {
	x="$1"
	case "$x" in
	*[Mm][Bb]) x=${x%[Mm][Bb]} ;; # режем mb ${var%pattern}
	*) die "Нужно указывать 'Mb' (пример 10Mb), получили: '$x'" ;;
	esac
	echo "$x"
}

rand_between() {
	lo="$1"
	hi="$2"
	echo $((lo + RANDOM % (hi - lo + 1)))
}
