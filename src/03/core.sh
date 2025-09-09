#!/bin/bash

# безопасно удаляем целевой корень (только в пределах ФС, с простыми страховками)
_rm_tree() {
	local d="$1"
	case "$d" in *bin* | *sbin*)
		printf "Пропуск (bin/sbin): %s\n" "$d"
		return 0
		;;
	esac
	[ -d "$d" ] || {
		printf "Нет папки: %s\n" "$d"
		return 0
	}
	# простая защита от случайных коротких путей
	[ "${#d}" -ge 10 ] || {
		printf "Слишком короткий путь (skip): %s\n" "$d"
		return 1
	}

	rm -rf --one-file-system -- "$d" &&
		printf "Удалён корень: %s\n" "$d" ||
		printf "Ошибка удаления: %s\n" "$d"
}

# читает список директорий; печатает только корни:
# у родителя basename НЕ оканчивается на _\d{6}
_roots_only() {
	awk -F/ '{
    n = split($0, a, "/");
    parent = (n>1 ? a[n-1] : "");
    if (parent !~ /_[0-9]{6}$/) print $0;
  }'
}

# берёт директории на stdin, оставляет только корни и удаляет их
_purge_roots_from_stdin() {
	_roots_only |
		sort -u |
		while IFS= read -r d; do
			[ -n "$d" ] || continue
			_rm_tree "$d"
		done
}

delete_by_log() {
	local log="$1"
	printf "[лог] %s\n" "$log"
	awk -F'|' '$1=="DIR"{print $2}' "$log" |
		_purge_roots_from_stdin
	printf "выполнено удаление по логу\n"
}

# где могли создаваться корни
_pick_bases() {
	for d in /home/* /tmp /var/tmp /opt /mnt/* /media/* /srv; do
		[ -d "$d" ] || continue
		case "$d" in *bin* | *sbin*) continue ;; esac
		[ -w "$d" ] && [ -x "$d" ] || continue
		printf "%s\n" "$d"
	done
}

delete_by_time() {
	local t_start="$1" t_end="$2"
	# включаем минуту конца
	local t_end_plus
	t_end_plus="$(date -d "$t_end +1 minute" '+%Y-%m-%d %H:%M')" || t_end_plus="$t_end"

	printf "[время] %s .. %s (вкл. минуту конца)\n" "$t_start" "$t_end"

	for base in $(_pick_bases); do
		find "$base" -xdev -type d \
			-name '*_[0-9][0-9][0-9][0-9][0-9][0-9]' \
			-newermt "$t_start" ! -newermt "$t_end_plus" \
			-print 2>/dev/null
	done |
		_purge_roots_from_stdin

	printf "выполнено удаление по времени\n"
}

# из букв делает шаблон вида a+b+c+ (порядок и «каждую букву ≥1 раз»)
_body_re_from_letters() {
	local s="$1" out="" i
	for ((i = 0; i < ${#s}; i++)); do
		out+="${s:i:1}+"
	done
	printf "%s" "$out"
}

delete_by_mask() {
	local mask="$1" # пример: az_080925
	local letters="${mask%%_*}"
	local dtag="${mask##*_}"

	local body_re="$(_body_re_from_letters "$letters")"
	local dir_re="^${body_re}_${dtag}$"
	printf "[маска] letters='%s' date='%s' ⇒ RE body='%s'\n" "$letters" "$dtag" "$body_re"

	for base in $(_pick_bases); do
		find "$base" -xdev -type d -name "*_${dtag}" -print 2>/dev/null
	done |
		_roots_only |
		sort -u |
		while IFS= read -r d; do
			local bn="${d##*/}"
			[[ "$bn" =~ $dir_re ]] && _rm_tree "$d"
		done

	printf "выполнено удаление по маске\n"
}
