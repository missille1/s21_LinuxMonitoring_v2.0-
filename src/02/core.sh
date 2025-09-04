#!/bin/bash

# создаем уникальные имена
# повторяем буквы несколько раз + префикс первых букв
seq_for_index() {
	letters="$1"
	idx="$2"

	# базовая часть >= 5 символов, сохраняем порядок
	base="$letters"
	while [ "${#base}" -lt 5 ]; do
		base="$base$letters"
	done

	# добавление уникальности idx-1 символов циклом по одной букве
	extra_cnt=$((idx - 1))
	if [ "$extra_cnt" -gt 0 ]; then
		# добавляем в конце по одной букве
		L=${#letters}
		reps=$(((extra_cnt + L - 1) / L))
		tail=""
		r=1
		while [ "$r" -le "$reps" ]; do
			tail="$tail$letters"
			r=$((r + 1))
		done
		# берем первый символ для tail
		tail=$(printf "%s" "$tail" | cut -c1-"$extra_cnt")
		base="$base$tail"
	fi

	printf "%s" "$base"
}

# выбор папок для скрипта
# write и executable
pick_bases() {
	for d in /home/* /tmp /var/tmp /opt /mnt/* /media/* /srv; do
		[ -d "$d" ] || continue
		case "$d" in
		*bin* | *sbin*) continue ;;
		esac
		[ -w "$d" ] && [ -x "$d" ] || continue
		echo "$d"
	done | head -n "${MAX_BASES:-3}" # максимум 3 папки
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

create_file_mb() {
	path="$1"
	size_kb="$2"
	# /dev/zero - создаст поток нулевых байтов, conv=fsync гарантирует запись на диск перед завершением
	# status - тихий режим
	dd if=/dev/zero of="$path" bs=1M count="$size_mb" conv=fsync status=none \
		|| die "Ошибка dd при создании файла: $path"
}

fmt_dur_hms() {
	s="$1"
	h=$((s / 3600))
	m=$(((s % 3600) / 60))
	sec=$((s % 60))
	printf "%02d:%02d:%02d" "$h" "$m" "$sec"
}

# запуск создания папок и файлов
run_core() {
	dtag="$(date +%d%m%y)"
	start_ts=$(date +%s)
	start_at=$(date +'%F %T')

	# лог кладем либо туда либо в тмп дял надежности
	log_base="/var/tmp"
	[ -w "$log_base" ] || log_base="/tmp"
	log="${log_base}/create_${dtag}_$(date +%H%M%S)_$$.log"
	printf "# type|fullpath|created_at|size_mb\n\n" >"$log"

	# выбираем папки для записи
	bases="$(pick_bases)"
	[ -n "$bases" ] || die "нет папок куда могу записать файлы"

	# рандомчик
	max_depth="${MAX_DEPTH:-100}"
	max_files="${MAX_FILES_PER_DIR:-7}"

	echo "$bases" | while read base_path; do
		# глубина
		depth="$(rand_between 1 "$max_depth")"

		# вложенные папки
		i=1
		current="$base_path"
		while [ "$i" -le "$depth" ]; do

			check_free_space_or_exit

			d_body="$(seq_for_index "$ARG_FILE_DIRS" "$i")"
			dir="${current}/${d_body}_${dtag}"

			mkdir -p "$dir" || die "Папка: $dir"
			printf "Папка %s\n" "$dir"
			printf "DIR|%s|%s|\n" "$dir" "$(date +'%F %T')" >>"$log"
			
			# случайное число файлов в папке
			nfiles="$(rand_between 1 "$max_files")"
			j=1
			while [ "$j" -le "$nfiles" ]; do
				check_free_space_or_exit

				f_body="$(seq_for_index "$ARG_FILE_LETTERS" "$j")"
				file="${dir}/${f_body}_${dtag}.${ARG_FILE_EXT}"

				create_file_mb "$file" "$ARG_SIZE_MB" || die "Ошибка создания файла: $file"
				printf "ФАЙЛ %s\n" "$file"
				printf "FILE|%s|%s|%s\n" "$file" "$(date +'%F %T')" "$ARG_SIZE_MB" >>"$log"
				j=$((j + 1))
			done
			current="$dir" # опускаемся вглубь внутри папки
			i=$((i + 1))
		done
	done

	end_ts=$(date +%s)
	end_at=$(date +'%F %T')
	dur=$((end_ts - start_ts))
	dur_hms="$(fmt_dur_hms "$dur")"

	printf "Начало: %s\nEND:	%s\nВыполнение: %s\n" "$start_at" "$end_at" "$dur_hms" | tee -a "$log"
}
