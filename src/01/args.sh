#!/bin/bash

# глобальные переменный после парсинга
ARG_PATH=""
ARG_N_DIRS=0
ARG_LETTERS_DIRS=""
ARG_N_FILES=0
ARG_FILE_LETTERS=""
ARG_FILE_EXT=""
ARG_SIZE_KB=0

parse_args() {
    if [ "$#" -ne 6 ]; then
        usage_short
        die "need exactly 6 params, got: $#"
    fi

    P1="$1"; P2="$2"; P3="$3"; P4="$4"; P5="$5"; P6="$6"

    # P1: абсолютный путь
    ensure_abs_path "$P1"
    ARG_PATH="$P1"

    # P2: кол-во папок >=1
    ensure_unit_ge "$P2" 1
    ARG_N_DIRS="$P2"

    # P3: буквы для папок [a-z], длина 1..7
    ensure_letters "$P3"
    ensure_len_range "$P3" 1 7
    ARG_LETTERS_DIRS="$P3"

    # P4: файлов на папку >=0
    ensure_unit_ge "$P4" 0
    ARG_N_FILES="$P4"

    # P5: letters.ext
    set -- $(split_letters_ext "$P5")
    name="$1"; ext="$2"
    ensure_letters "$name"; ensure_len_range "$name" 1 7
    ensure_letters "$ext"; ensure_len_range "$ext" 1 3 
    ARG_FILE_LETTERS="$name"
    ARG_FILE_EXT="$ext"

    # P6: размер в КБ (1..100), <3> или <3kb>
    size="$(normalize_size_kb "$P6")"
    ensure_unit_between "$size" 1 100
    ARG_SIZE_KB="$size"
}