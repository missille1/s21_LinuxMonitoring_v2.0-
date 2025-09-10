#!/bin/bash

die() { printf "Ошибка: %s\n" "$*" >&2; exit 1; }

# Скрипт запускается БЕЗ аргументов
check_no_args() {
  if [ "$#" -ne 0 ]; then
    die "скрипт не принимает аргументы. Запускайте: ./main.sh"
  fi
}

rand_int() { 
  local lo="$1" hi="$2"
  echo $(( lo + (RANDOM % (hi - lo + 1)) ))
}

# Выбор случайного элемента массива
rand_pick() {
  local arr=("$@")
  local idx
  idx=$(rand_int 0 $((${#arr[@]} - 1))) # {#arr[@]} выводим количество эл. массива
  printf '%s' "${arr[$idx]}" # выводим имя элемента
}
