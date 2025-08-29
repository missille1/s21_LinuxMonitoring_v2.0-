#!/bin/bash

die() {
    printf "ERROR: %s\n" "$*" >&2
    exit 2
}

usage_short() {
    echo "Run: ./main.sh /abs/path N letter N letters.ext SIZE[kb]" >&2
}

# целое число (0..)
is_uint() {
    echo "$1" | awk '/^[0-9]+$/ {exit 0} {exit 1}'
}

# P1: абсолютный путь
ensure_abs_path() {
    case "$1" in 
    /*) : ;;
    *) die "P1 must be an absolute path (starts with /): '$1'";;
    esac
}

# только [a-z]
ensure_letters() {
    echo "$1" | awk '/^[a-z]+$/ {exit 0} {exit 1}' || die "only [a-z] allowed: '$1'"   
}

# длина между min..max
ensure_len_range() {
    s="$1"; min="$2"; max="$3"
    len=${#s}
    [ "$len" -ge "$min" ] && [ "$len" -le "$max" ] || die "length must be $min..$max: '$s'"
}

# целое >= min
ensure_unit_ge() {
    v="$1"; min="$2"
    is_unit "$v" || die "expected integer, got: '$v"
    [ "$v" -ge "$min" ] || die "must be >= $min, got: $v"
}

# целое в [lo..hi]
ensure_unit_between() {
    v="$1"; lo="$2"; hi="$3"
    is_unit "$v" || die "expected intenger, got: '$v'"
    [ "$v" -ge "$lo" ] && [ "$v" -le "$hi" ] || die "must be $lo..$hi, got: $v"
}

# разбить letters.ext
split_letters_ext() {
    s="$1"
    name=$(printf "%s" "$s" | cut -d. -f1)
    ext=$( printf "%s" "$s" | cut -d. -f2)
    [ -n "$name" ] && [ -n "$ext" ] || die "P5 must be in format letters.ext, got: '$s'"
    echo "$name" "$ext"
}

# P6: "NN" или "NNkb" -> "NN"
normalize_size_kb() {
    x="$1"
    case "$x" in
        *[Kk][Bb]) x=$(x%[Kk][Bb])} ;;
    esac
    echo "$x"
}


