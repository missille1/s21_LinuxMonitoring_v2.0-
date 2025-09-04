#!/bin/bash

# глобальные переменный после парсинга
ARG_LETTERS_DIRS=""
ARG_FILE_LETTERS=""
ARG_FILE_EXT=""
ARG_SIZE_MB=0

parse_args() {
    if [ "$#" -ne 3 ]; then
        usage_short
        die "Нужно 3 параметра, получили: $#"
    fi

    P1="$1"; P2="$2"; P3="$3"

    # P1: буквы для папок [a-z], длина 1..7
    ensure_letters "$P1"
    ensure_len_range "$P1" 1 7
    ARG_LETTERS_DIRS="$P1"

    # P2: letters.ext
    set -- $(split_letters_ext "$P2") # -- не перезаписываем позиционные параметры 
    name="$1"; ext="$2"
    ensure_letters "$name"; ensure_len_range "$name" 1 7
    ensure_letters "$ext"; ensure_len_range "$ext" 1 3 
    ARG_FILE_LETTERS="$name"
    ARG_FILE_EXT="$ext"

    # P3: размер в MБ (1..100)
    size="$(normalize_size_mb "$P3")"
    ensure_unit_between "$size" 1 100
    ARG_SIZE_MB="$size"
}