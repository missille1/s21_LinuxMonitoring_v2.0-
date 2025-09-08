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

_body_re_from_letters() {
  letters="$1"
  out=""
  i=1
  while [ "$i" -le "${#letters}" ]; do
    ch=$(printf "%s" "$letters" | cut -c"$i")
    out="${out}${ch}+"
    i=$((i+1))
  done
  printf "%s" "$out"
}

_pick_bases() {
  for d in /home/* /tmp /var/tmp /opt /mnt/* /media/* /srv; do
    [ -d "$d" ] || continue
    case "$d" in *bin*|*sbin*) continue ;; esac
    [ -w "$d" ] && [ -x "$d" ] || continue
    echo "$d"
  done
}

delete_by_time() {
  t_start="$1"      # "YYYY-MM-DD HH:MM"
  t_end="$2"        # "YYYY-MM-DD HH:MM"
  t_end_plus="$(date -d "$t_end +1 minute" '+%Y-%m-%d %H:%M')" || t_end_plus="$t_end"

  echo "[время] $t_start .. $t_end (вкл. минуту конца)"

  # файлы сначала
  for base in $(_pick_bases); do
    find "$base" -xdev -type f \
      -newermt "$t_start" ! -newermt "$t_end_plus" \
      -print 2>/dev/null \
    | awk '/_[0-9]{6}\.[a-z]{1,3}$/ {print $0}' \
    | while read -r f; do
        _rm_file "$f"
      done

    # затем папки (глубокие → вверх)
    find "$base" -xdev -type d \
      -newermt "$t_start" ! -newermt "$t_end_plus" \
      -print 2>/dev/null \
    | awk '/_[0-9]{6}$/ {print $0}' \
    | awk -F/ '{print NF ":" $0}' | sort -t: -k1,1nr | cut -d: -f2- \
    | while read -r d; do
        _rmdir_path "$d"
      done
  done

  echo "выполнено удаление по времени"
}

delete_by_mask() {
  mask="$1"                          # например: az_080925
  letters="$(printf "%s" "$mask" | cut -d_ -f1)"
  dtag="$(printf "%s" "$mask" | cut -d_ -f2)"
  body_re="$(_body_re_from_letters "$letters")"
  dir_re="^${body_re}_${dtag}$"
  file_re="^${body_re}_${dtag}\.[a-z]{1,3}$"

  echo "[маска] letters='$letters' date='$dtag' ⇒ RE body='$body_re'"

  # файлы
  for base in $(_pick_bases); do
    find "$base" -xdev -type f -name "*_${dtag}.*" -print 2>/dev/null \
    | while read -r p; do
        bn="$(basename "$p")"
        printf "%s\n" "$bn" \
        | awk -v re="$file_re" 'BEGIN{e=1} $0 ~ re {e=0} END{exit e}' \
        && _rm_file "$p"
      done

    # папки (deep first)
    find "$base" -xdev -type d -name "*_${dtag}" -print 2>/dev/null \
    | awk -F/ '{print NF ":" $0}' | sort -t: -k1,1nr | cut -d: -f2- \
    | while read -r d; do
        bn="$(basename "$d")"
        printf "%s\n" "$bn" \
        | awk -v re="$dir_re" 'BEGIN{e=1} $0 ~ re {e=0} END{exit e}' \
        && _rmdir_path "$d"
      done
  done

  echo "выполнено удаление по маске"
}