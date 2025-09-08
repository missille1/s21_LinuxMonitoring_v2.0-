#!/bin/bash

# глобальные переменный после парсинга
ARG_MODE=0
ARG_LOG=""
ARG_T_START=""
ARG_T_END=0
ARG_MASK=""

ensure_readable_file() {
	f="$1"
	[ -f "$f" ] && [ -r "$f" ] || { printf "Ошибка: лог не может быть прочитан: %s\n" "$f" >&2; return 1; }
}

ask_mode(){
  while :; do
    printf "Выберите режим (1=по логу, 2=по времени, 3=по маске): "
    read -r ans
    case "$ans" in 1|2|3) ARG_MODE="$ans"; return 0;; *) echo "Введите 1, 2 или 3.";; esac
  done
}

ask_log(){
  while :; do
    printf "Путь к лог-файлу: "
    read -r p
    [ -n "$p" ] || { echo "Пусто — введите путь."; continue; }
    ensure_readable_file "$p" && ARG_LOG="$p" && return 0
  done
}

ask_mask(){
  while :; do
    printf "Маска (letters_DDMMYY): "
    read -r m
    # letters: 1..7 a-z, дата: 6 цифр
    printf "%s" "$m" | awk '/^[a-z]{1,7}_[0-9]{6}$/ {exit 0} {exit 1}' \
      && { ARG_MASK="$m"; return 0; } || echo "Пример: az_080925"
  done
}

ask_time_range(){
  while :; do
    printf "Время начала (YYYY-MM-DD HH:MM): "
    read -r t1
    s1="$(norm_time_min "$t1")"; [ -n "$s1" ] || { echo "Неверный формат."; continue; }
    e1="$(time_to_epoch "$s1")"

    printf "Время конца   (YYYY-MM-DD HH:MM): "
    read -r t2
    s2="$(norm_time_min "$t2")"; [ -n "$s2" ] || { echo "Неверный формат."; continue; }
    e2="$(time_to_epoch "$s2")"

    [ "$e1" -le "$e2" ] || { echo "Старт позже конца — повторите."; continue; }
    ARG_T_START="$s1"; ARG_T_END="$s2"; return 0
  done
}

# парсер: только 0 или 1 аргумент (режим). остальное — спрашиваем.
parse_args(){
  [ "$#" -le 1 ] || die "ожидается только 1 параметр — режим (1/2/3)"
  if [ "$#" -eq 1 ]; then
    case "$1" in 1|2|3) ARG_MODE="$1";; *) die "режим должен быть 1, 2 или 3";; esac
    printf "[ok] параметр=%s\n" "$ARG_MODE"
  else
    ask_mode
  fi

  case "$ARG_MODE" in
    1) ask_log ;;
    2) ask_time_range ;;
    3) ask_mask ;;
    *) die "unknown mode: $ARG_MODE" ;;
  esac
  return 0
}