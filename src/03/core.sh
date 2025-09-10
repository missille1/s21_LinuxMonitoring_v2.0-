#!/bin/bash

_rm_tree() {
	d="$1"
	case "$d" in *bin* | *sbin*)
		echo "Пропуск (bin/sbin): $d"
		return 0
		;;
	esac
	[ -d "$d" ] || {
		echo "Нет папки: $d"
		return 0
	}
	# защита от случайных коротких путей
	[ "${#d}" -ge 10 ] || {
		echo "Слишком короткий путь (skip): $d"
		return 1
	}
	rm -rf --one-file-system -- "$d" &&
		echo "Удалён корень: $d" ||
		echo "Ошибка удаления: $d"
}

# сортируем наш лог и ищем корневые папки
_roots_only() {
	awk -F/ '{
    n = split($0, a, "/");
    parent = (n>1 ? a[n-1] : "");
    if (parent !~ /_[0-9]{6}$/) print $0;
  }'
}

_purge_all_create_logs() {
  local removed=0
  for d in /var/tmp /tmp; do
    [ -d "$d" ] || continue
    find "$d" -maxdepth 1 -xdev -type f -name 'create_*.log' -print0 2>/dev/null \
    | while IFS= read -r -d '' f; do
        if rm -f "$f"; then
          printf "Удалён лог: %s\n" "$f"
        else
          printf "Ошибка удаления лога: %s\n" "$f"
        fi
      done
  done
}

delete_by_log() {
	log="$1"
	echo "[лог] $log"

	awk -F'|' '$1=="DIR"{print $2}' "$log" |
		sort -u |
		_roots_only |
		sort -u |
		while read -r d; do
			[ -n "$d" ] || continue
			_rm_tree "$d"
		done
	_purge_all_create_logs
	echo "выполнено удаление по логу"
}

_pick_bases() {
	for d in /home/* /tmp /var/tmp /opt /mnt/* /media/* /srv; do
		[ -d "$d" ] || continue
		case "$d" in *bin* | *sbin*) continue ;; esac
		[ -w "$d" ] && [ -x "$d" ] || continue
		echo "$d"
	done
}

delete_by_time() {
	t_start="$1"
	t_end="$2"
	t_end_plus="$(date -d "$t_end +1 minute" '+%Y-%m-%d %H:%M')" || t_end_plus="$t_end"

	echo "[время] $t_start .. $t_end (вкл. минуту конца)"
	# newermt временная метка
	for base in $(_pick_bases); do
		find "$base" -xdev -type d \
			-name '*_[0-9][0-9][0-9][0-9][0-9][0-9]' \
			-newermt "$t_start" ! -newermt "$t_end_plus" \
			-print 2>/dev/null
	done |
		sort -u |
		_roots_only |
		sort -u |
		while read -r d; do
			_rm_tree "$d"
		done
	_purge_all_create_logs
	echo "выполнено удаление по времени"
}

# из букв делает шаблон вида a+b+c+  (порядок и «каждую букву ≥1 раз»)
_body_re_from_letters() {
	s="$1"
	out=""
	i=1
	while [ "$i" -le "${#s}" ]; do
		ch=$(printf "%s" "$s" | cut -c"$i")
		out="${out}${ch}+"
		i=$((i + 1))
	done
	printf "%s" "$out"
}

delete_by_mask() {
	mask="$1"
	letters="${mask%%_*}"
	dtag="${mask##*_}"

	body_re="$(_body_re_from_letters "$letters")"
	dir_re="^${body_re}_${dtag}$"
	echo "[маска] letters='${letters}' date='${dtag}' ⇒ RE body='${body_re}'"

	for base in $(_pick_bases); do
		find "$base" -xdev -type d -name "*_${dtag}" -print 2>/dev/null
	done |
		sort -u |
		_roots_only |
		sort -u |
		while read -r d; do
			bn="${d##*/}"                   # /tmp/log - log
			if [[ "$bn" =~ $dir_re ]]; then # проверяем на любое а+z+
				_rm_tree "$d"
			fi
		done
	_purge_all_create_logs
	echo "выполнено удаление по маске"
}
