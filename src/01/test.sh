split_letters_ext() {
  s="$1"
  name="${s%%.*}"
  ext="${s##*.}"
  printf '%s %s\n' "$name" "$ext"
}

P5="az.az"

# до:
echo "до: \$1='$1' \$2='$2'"

set -- $(split_letters_ext "$P5")

# после:
echo "после: \$1='$1' \$2='$2'"
# удобно сохранить:
name="$1"; ext="$2"
echo "name='$name' ext='$ext'"
