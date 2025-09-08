#!/bin/bash

_rm_file() {
	f="$1"
	case "$f" in *bin*|*sbin*) printf "Пропускаем (bin/sbin): %s\n" "$f"; return 0; esac
	if [ -e "$f" ]; then
		rm -f -- "$f" >/dev/null 2>&1 && printf "Удален файл %s\n" "$f" || \
		printf "Ошибка файл не удален %s\n" "$f"
	else
		printf "Пропущен файл %s\n" "$f"
	fi
}

_rmdir_path() {
	d="$1"
	case "$d" in *bin*|*sbin*) printf "Пропускаем (bin/sbin): %s\n" "$d"; return 0; esac
	if [ -d "$d" ]; then
		rmdir -d -- "$d" >/dev/null 2>&1 && printf "Удалена папка %s\n" "$d" || \
		printf "Ошибка папка не удалена %s\n" "$d"
	else
		printf "Пропущена папка %s\n" "$d"
	fi
}

delete_by_log() {
	log="$1"
	printf "[лог] %s\n" "$log"

	#соберем список файлов и папок
	files=$(awk -F'|' '$1=="FILE"{print $2}' "$log" | sort -u)
	dirs=$(awk -F'|' '$1=="DIR"{print $2}' "$log" | tac) # cat перевернут

	printf "удаляем файлы\n"
	for f in $files; do
		[ -n "$f" ] || continue
		_rm_file "$f"
	done

	printf "удаляем папки\n"
	for d in $dirs; do
		[ -n "$d" ] || continue
		_rmdir_path "$d"
	done
	
	printf "выполнено удаление по логу\n"
}

