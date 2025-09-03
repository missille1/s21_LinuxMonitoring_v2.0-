#!/bin/bash

source ./util.sh
source ./args.sh
source ./core.sh

set -u 

print_usage() {
    echo "Usage:"
    echo " ./main.sh <abs_path> <folders_count> <letters_dirs> <files_per_dir> <letters.ext> <size_kb|sizekb>"
    echo "Example:"
    echo " ./main.sh /opt/test/ 4 az 5 az.az 3kb"
}

parse_args "$@" || exit 2

printf "[OK] parsed:\n"
printf " path           = %s\n" "$ARG_PATH"
printf " folders        = %s\n" "$ARG_N_DIRS"
printf " letters_dirs   = %s\n" "$ARG_LETTERS_DIRS"
printf " files/dir      = %s\n" "$ARG_N_FILES"
printf " letters.ext    = %s.%s\n" "$ARG_FILE_LETTERS" "$ARG_FILE_EXT"
printf " size.kb        = %s\n" "$ARG_SIZE_KB"

run_core

# check file size
# du -B1 --apparent-size /tmp/xtest1/azaz_030925/azaz_030925.az
# MIN_FREE_KB=8651600 ./main.sh /tmp/xtest1 4 az 5 az.az 3kb ; echo $?
