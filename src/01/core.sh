#!/bin/bash

# дата
date_tag() {
	date +%d%m%y
}

# создаем уникальные имена
# повторяем буквы несколько раз + префикс первых букв
seq_for_index() {
	letters="$1"
	idx="$2"
	minlen=4 # для 01 minlen=4
	L=${#letters}

	if [ "$L" -gt "$minlen" ]; then
		target_base="$L"
	else
		target_base="$minlen"
	fi

	target=$((target_base + idx - 1))
	extra=$((target - L))
	[ "$extra" -lt 0 ] && extra=0

	q=$((extra / L)) # добавить каждой букве
	r=$((extra % L)) # первым r буквам ещё по 1

	out=""
	p=1
	while [ "$p" -le "$L" ]; do
		ch=$(printf "%s" "$letters" | cut -c"$p")
		cnt=$((1 + q))
		[ "$p" -le "$r" ] && cnt=$((cnt + 1))
		k=1
		while [ "$k" -le "$cnt" ]; do
			out="${out}${ch}"
			k=$((k + 1))
		done
		p=$((p + 1))
	done

	printf "%s" "$out"
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
	path="$1"
	size_kb="$2"
	# /dev/zero - создаст поток нулевых байтов, conv=fsync гарантирует запись на диск перед завершением
	# status - тихий режим
	dd if=/dev/zero of="$path" bs=1K count="$size_kb" conv=fsync status=none ||
		die "Ошибка dd при создании файла: $path"
}

# запуск создания папок и файлов
run_core() {
	# по директории
	# по файлам в каждой папке
	base_path="${ARG_PATH%/}"
	dtag="$(date_tag)"
	log="${base_path}/create_${dtag}_$(date +%H%M%S).log"

	# создание
	mkdir -p "$base_path" 2>/dev/null || die "Не могу создать базовую директорию: $base_path"
	printf "# type|fullpath|created_at|size_kb|size_bytes\n\n" >"$log"

	i=1
	while [ "$i" -le "$ARG_N_DIRS" ]; do
		check_free_space_or_exit

		d_body="$(seq_for_index "$ARG_LETTERS_DIRS" "$i" 4)"
		dir="${base_path}/${d_body}_${dtag}"

		mkdir -p "$dir" || die "Ошибка mkdir: $dir"
		printf "DIR|%s|%s|\n" "$dir" "$(date +'%F %T')" >>"$log"
		printf "Папка %s\n" "$dir"

		j=1
		while [ "$j" -le "$ARG_N_FILES" ]; do
			check_free_space_or_exit

			f_body="$(seq_for_index "$ARG_FILE_LETTERS" "$j" 4)"
			file="${dir}/${f_body}_${dtag}.${ARG_FILE_EXT}"

			create_file_kb "$file" "$ARG_SIZE_KB" || die "Ошибка создания файла: $file"
			bytes=$(stat -c %s "$file" 2>/dev/null)
			printf "ФАЙЛ %s\n" "$file"
			printf "FILE|%s|%s|%sKB|%sB\n" "$file" "$(date +'%F %T')" "$ARG_SIZE_KB" "$bytes" >>"$log"

			j=$((j + 1))

		done

		i=$((i + 1))
	done

	printf "\n[ok] Создано. Лог: %s\n" "$log"
}
