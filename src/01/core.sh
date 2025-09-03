#!/bin/bash

# дата
date_tag() {
  date +%d%m%y
}

# даем имя не короче N, повторяя заданные буквы
pad_to_min_len() {
  letters="$1"; need="$2"
  out="$letters"
  # проверка что длина не 0
  while [ "${#out}" -lt "$need" ]; do
    out="$out$letters"
  done
  printf "%s" "$out"
}

# создаем уникальные имена
# повторяем буквы несколько раз + префикс первых букв 
seq_for_index() {
  letters="$1"; idx="$2"
  
  # базовая часть >= 4 символов, сохраняем порядок
  base="$letters"
  while [ "${#base}" -lt 4 ]; do
    base="$base$letters"
  done

  # добавление уникальности idx-1 символов циклом по одной букве
  extra_cnt=$((idx - 1))
  if [ "$extra_cnt" -gt 0 ]; then
    # добавляем в конце по одной букве
    L=${#letters}
    reps=$(( (extra_cnt + L - 1)/ L))
    tail=""
    r=1
    while [ "$r" -le "$reps" ]; do
      tail="$tail$letters"
      r=$((r+1))
    done
    # берем первый символ для tail
    tail=$(printf "%s" "$tail" | cut -c1-"$extra_cnt")
    base="$base$tail"
  fi

  printf "%s" "$base"
}

# генерируем имена директорий 
plan_dirs() {
  base_path="$ARG_PATH"
  letters="$ARG_LETTERS_DIRS"
  n="$ARG_N_DIRS"
  dtag="$(date_tag)"

  i=1
  while [ "$i" -le "$n" ]; do
    body="$(seq_for_index "$letters" "$i")"
    name="${body}_${dtag}"
    printf "Папка %s/%s\n" "$base_path" "$name"
    i=$((i+1))
  done
}

# генерируем имена файлов для одной директории 
plan_files_for_dir() {
  dir_full="$1"
  letters="$ARG_FILE_LETTERS"
  ext="$ARG_FILE_EXT"
  n="$ARG_N_FILES"
  dtag="$(date_tag)"

  j=1
  while [ "$j" -le "$n" ]; do
    body="$(seq_for_index "$letters" "$j")"
    # имя дата расширение
    fname="${body}_${dtag}.${ext}"
    printf "ФАЙЛ %s/%s\n" "$dir_full" "$fname"
    j=$((j+1))
  done
}

# проверка freespace
check_free_space_or_exit() {
  # 1 gb = 1048576 kb
  min_free_kb="${MIN_FREE_KB:-1048576}" # берем либо глобалку либо указанный размер
  avail_kb=$(df -Pk / | awk 'NR==2{print $4}')
  if [ "$avail_kb" -le "$min_free_kb" ]; then
    printf "Недостаточно места в /: %sКБ <= %sКБ - скрипт остановлен\n" "$avail_kb" "$min_free_kb" >&2
    exit 3
  fi
}

create_file_kb() {
  path="$1"; size_kb="$2"
  # /dev/zero - создаст поток нулевых байтов, conv=fsync гарантирует запись на диск перед завершением
  # status - тихий режим
  dd if=/dev/zero of="$path" bs=1K count="$size_kb" conv=fsync status=none \
    || die "Ошибка dd при создания файла: $path"
}

# запуск создания папок и файлов
run_core() {
  # по директории
  # по файлам в каждой папке
  base_path="${ARG_PATH%/}"
  dtag="$(date_tag)"
  log="${base_path}/create_${dtag}_$(date +%H%M%S).log"

  # создание 
  mkdir -p "$base_path" || die "Не могу создать базовую директорию: $base_path"
  printf "# type|fullpath|created_at|size\n" > "$log"

  i=1
  while [ "$i" -le "$ARG_N_DIRS" ]; do
    check_free_space_or_exit

    d_body="$(seq_for_index "$ARG_LETTERS_DIRS" "$i")"
    dir="${base_path}/${d_body}_${dtag}"

    mkdir -p "$dir" || die "Ошибка mkdir: $dir"
    printf "DIR|%s|%s|\n" "$dir" "$(date +'%F %T')" >> "$log"
    printf "Папки %s\n" "$dir"

    j=1
    while [ "$j" -le "$ARG_N_FILES" ]; do
      check_free_space_or_exit

      f_body="$(seq_for_index "$ARG_FILE_LETTERS" "$j")"
      file="${dir}/${f_body}_${dtag}.${ARG_FILE_EXT}"

      create_file_kb "$file" "$ARG_SIZE_KB" || die "Ошибка создания файла: $file"
      printf "ФАЙЛ %s\n" "$file"
      printf "FILE|%s|%s|%sKB\n" "$file" "$(date +'%F %T')" "$ARG_SIZE_KB" >> "$log"

      j=$((j+1))

    done

    i=$((i+1))
  done

  printf "\n[ok] Создано. Лог: %s\n" "$log"
}


  # печатаем 
#  while [ "$i" -le "$ARG_N_DIRS" ]; do
#    body="$(seq_for_index "$ARG_LETTERS_DIRS" "$i")"
#    dname="${body}_$(date_tag)"
#    dfull="${base_path}/${dname}"
#
#  printf "Папки %s\n" "$dfull"
#   # файлы для каждой папки
#   plan_files_for_dir "$dfull"
#
#   i=$((i+1))
#done

#   printf "\n[hint] Потом будем реально делать.\n"
# }
