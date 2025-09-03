#!/bin/bash

die() {
    printf "Ошибка: %s\n" "$*" >&2 # перевод ошибок в stderr, * все аргументы в одну строку
    exit 2
}

print_info() {
    printf "[OK] parsed:\n"
    printf " path           = %s\n" "$ARG_PATH"
    printf " folders        = %s\n" "$ARG_N_DIRS"
    printf " letters_dirs   = %s\n" "$ARG_LETTERS_DIRS"
    printf " files/dir      = %s\n" "$ARG_N_FILES"
    printf " letters.ext    = %s.%s\n" "$ARG_FILE_LETTERS" "$ARG_FILE_EXT"
    printf " size.kb        = %s\n" "$ARG_SIZE_KB"
}

usage_short() {
    echo "Использование:" >&2
    echo " ./main.sh <abs_path> <folders_count> <letters_dirs> <files_per_dir> <letters.ext> <sizekb>" >&2
    echo "Пример:" >&2
    echo " ./main.sh /tmp/test 4 az 5 az.az 3kb" >&2
}

# целое число (0..)
is_unit() {
    echo "$1" | awk '/^[0-9]+$/ {exit 0} {exit 1}' # при успехе 0 при не удаче 1
}

# P1: абсолютный путь
ensure_abs_path() {
    case "$1" in 
    /*) : ;; # : ничего не делаем
    *) die "P1 должен быть абсолютный путь (/): '$1'";;
    esac
}

# только [a-z]
ensure_letters() {
    echo "$1" | awk '/^[a-z]+$/ {exit 0} {exit 1}' || die "Доступны буквы [a-z]: '$1'"   
}

# длина между min..max
ensure_len_range() {
    s="$1"; min="$2"; max="$3"
    len=${#s} # ${#var} возвращает длину значения
    [ "$len" -ge "$min" ] && [ "$len" -le "$max" ] || die "Длина должна быть $min..$max: '$s'"
}

# целое >= min
ensure_unit_ge() {
    v="$1"; min="$2"
    is_unit "$v" || die "Должно быть число, получили: '$v'"
    [ "$v" -ge "$min" ] || die "Должно быть папок >= $min, Получили: $v"
}

# целое в [lo..hi]
ensure_unit_between() {
    v="$1"; lo="$2"; hi="$3"
    is_unit "$v" || die "Должно быть число, получили: '$v'"
    [ "$v" -ge "$lo" ] && [ "$v" -le "$hi" ] || die "Должно быть $lo..$hi, получили: $v"
}

# разбить letters.ext
split_letters_ext() {
    s="$1"
    name=$(printf "%s" "$s" | cut -d. -f1)
    ext=$(printf "%s" "$s" | cut -d. -f2)
    # -n не пусто
    [ -n "$name" ] && [ -n "$ext" ] || die "P5 должно быть в формате az.az, получили: '$s'" 
    echo "$name" "$ext"
}

# P6: "NN" или "NNkb" -> "NN"
normalize_size_kb() {
    x="$1"
    case "$x" in
        *[Kk][Bb]) x=${x%[Kk][Bb]} ;; # режем кб ${var%pattern}
        *) die "Нужно указывать 'kb' (пример 10kb), получили: '$x'";; 
    esac
    echo "$x"
}


