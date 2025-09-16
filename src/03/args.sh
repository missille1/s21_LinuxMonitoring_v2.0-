#!/bin/bash

# глобальные переменный после парсинга
# глобалки
ARG_MODE=0
ARG_LOG=""
ARG_T_START=""
ARG_T_END=""
ARG_MASK=""

ask_log() {
	while :; do
		printf "Путь к лог-файлу: "
		read -r p
		[ -n "$p" ] || {
			echo "Пусто — введите путь."
			continue
		}
		ensure_readable_file "$p"
		ARG_LOG="$p"
		return 0
	done
}

ask_time_range() {
  while :; do
    printf "Время начала (YYYY-MM-DD HH:MM): "
    read -r t1
    #  требуем время
    require_datetime_with_minutes "$t1" || { echo "Нужно указать ДАТУ И ВРЕМЯ в формате YYYY-MM-DD HH:MM."; continue; }
    # валидность даты
    s1="$(norm_time_min "$t1")"
    [ -n "$s1" ] || { echo "Неверная дата/время."; continue; }
    e1="$(time_to_epoch "$s1")" || { echo "Неверная дата/время."; continue; }

    printf "Время конца   (YYYY-MM-DD HH:MM): "
    read -r t2
    require_datetime_with_minutes "$t2" || { echo "Нужно указать ДАТУ И ВРЕМЯ в формате YYYY-MM-DD HH:MM."; continue; }
    s2="$(norm_time_min "$t2")"
    [ -n "$s2" ] || { echo "Неверная дата/время."; continue; }
    e2="$(time_to_epoch "$s2")" || { echo "Неверная дата/время."; continue; }

    [ "$e1" -le "$e2" ] || { echo "Старт позже конца — повторите."; continue; }

    ARG_T_START="$s1"
    ARG_T_END="$s2"
    return 0
  done
}

ask_mask() {
	while :; do
		printf "Маска (letters_DDMMYY): "
		read -r m
		printf "%s" "$m" | awk '/^[a-z]{1,7}_[0-9]{6}$/ {exit 0} {exit 1}' &&
			{
				ARG_MASK="$m"
				return 0
			} || echo "Пример: az_080925"
	done
}

parse_args() {
	# строго ОДИН параметр (режим). Если нет — ошибка.
	[ "$#" -eq 1 ] || die "использование: $0 <режим: 1|2|3>"
	case "$1" in
	1)
		ARG_MODE=1
		printf "[ok] параметр=1\n"
		ask_log
		;;
	2)
		ARG_MODE=2
		printf "[ok] параметр=2\n"
		ask_time_range
		;;
	3)
		ARG_MODE=3
		printf "[ok] параметр=3\n"
		ask_mask
		;;
	*) die "режим должен быть 1, 2 или 3" ;;
	esac
	return 0
}
