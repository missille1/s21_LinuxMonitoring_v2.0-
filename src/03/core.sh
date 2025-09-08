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
		rmdir -- "$d" >/dev/null 2>&1 && printf "Удалена папка %s\n" "$d" || \
		printf "Ошибка папка не удалена %s\n" "$d"
	else
		printf "Пропущена папка %s\n" "$d"
	fi
}

# delete_by_log() {
#   log="$1"
#   printf "[лог] %s\n" "$log"

#   printf "удаляем файлы\n"
#   awk -F'|' '$1=="FILE"{print $2}' "$log" \
#     | sort -u \
#     | while read -r f; do
#         [ -n "$f" ] || continue
#         _rm_file "$f"
#       done
# #соберем список файлов и папок. NF нумеруем по количеству /. Сортируем по высоте. Убираем номера. 	
#   printf "удаляем папки\n"
#   awk -F'|' '$1=="DIR"{print $2}' "$log" \
#     | sort -u \
#     | awk -F/ '{print NF ":" $0}' \
#     | sort -t: -k1,1nr \
#     | cut -d: -f2- \
#     | while read -r d; do
#         [ -n "$d" ] || continue
#         _rmdir_path "$d"
#       done

#   printf "выполнено удаление по логу\n"
# }

delete_by_log() {
  log="$1"
  printf "[лог] %s\n" "$log"

  # файлы — по одному в строке
  files=$(awk -F'|' '$1=="FILE"{print $2}' "$log" | sort -u)

  # директории — уникальные, отсортированы по глубине (самые глубокие вперёд)
  dirs=$(awk -F'|' '$1=="DIR"{print $2}' "$log" \
        | sort -u \
        | awk -F/ '{print NF ":" $0}' \
        | sort -t: -k1,1nr \
        | cut -d: -f2-)

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