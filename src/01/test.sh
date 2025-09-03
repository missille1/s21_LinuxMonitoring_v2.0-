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