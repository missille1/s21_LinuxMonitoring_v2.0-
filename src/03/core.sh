#!/bin/bash

_rm_tree() {
  d="$1"
  case "$d" in *bin*|*sbin*) echo "Пропуск (bin/sbin): $d"; return 0;; esac
  [ -d "$d" ] || { echo "Нет папки: $d"; return 0; }
  # защита от случайных коротких путей
  [ "${#d}" -ge 10 ] || { echo "Слишком короткий путь (skip): $d"; return 1; }
  rm -rf --one-file-system -- "$d" \
    && echo "Удалён корень: $d" \
    || echo "Ошибка удаления: $d"
}

# читает: список директорий на stdin
# печатает: только корневые (у родителя basename НЕ оканчивается на _\d{6})
_roots_only() {
  awk -F/ '{
    n = split($0, a, "/");
    parent = (n>1 ? a[n-1] : "");
    if (parent !~ /_[0-9]{6}$/) print $0;
  }'
}

delete_by_log() {
  log="$1"
  echo "[лог] $log"

  awk -F'|' '$1=="DIR"{print $2}' "$log" \
    | sort -u \
    | _roots_only \
    | sort -u \
    | while read -r d; do
        [ -n "$d" ] || continue
        _rm_tree "$d"
      done

  echo "выполнено удаление по логу"
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

  for base in $(_pick_bases); do
    find "$base" -xdev -type d \
      -name '*_[0-9][0-9][0-9][0-9][0-9][0-9]' \
      -newermt "$t_start" ! -newermt "$t_end_plus" \
      -print 2>/dev/null
  done \
  | sort -u \
  | _roots_only \
  | sort -u \
  | while read -r d; do
      _rm_tree "$d"
    done

  echo "выполнено удаление по времени"
}

# из букв делает шаблон вида a+b+c+  (порядок и «каждую букву ≥1 раз»)
_body_re_from_letters() {
  s="$1"; out=""
  i=1; while [ "$i" -le "${#s}" ]; do
    ch=$(printf "%s" "$s" | cut -c"$i")
    out="${out}${ch}+"
    i=$((i+1))
  done
  printf "%s" "$out"
}

delete_by_mask() {
  mask="$1"                           # пример: az_080925
  letters="${mask%%_*}"
  dtag="${mask##*_}"

  body_re="$(_body_re_from_letters "$letters")"
  dir_re="^${body_re}_${dtag}$"
  echo "[маска] letters='${letters}' date='${dtag}' ⇒ RE body='${body_re}'"

  for base in $(_pick_bases); do
    find "$base" -xdev -type d -name "*_${dtag}" -print 2>/dev/null
  done \
  | sort -u \
  | _roots_only \
  | sort -u \
  | while read -r d; do
      bn="${d##*/}"
      if [[ "$bn" =~ $dir_re ]]; then
        _rm_tree "$d"
      fi
    done

  echo "выполнено удаление по маске"
}