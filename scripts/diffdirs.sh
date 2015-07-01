#!/bin/bash


function get_dir_info() {
  zopt=${1:-""}
  zdir=${2:-"."}

  if [ "$zopt" = "-s" ]; then
    ls -Fs "$zdir" | sed 's#\*$##g' | sort -k 2 |  grep -v "^total"
  else
    ls -F "$zdir" | sed 's#\*$##g'
  fi

}  #   End of function  get_dir_info.


function print_dir_diffs() {
  sizeopt=$3
  tmpf=/tmp/diffdirs.$$
  get_dir_info "$sizeopt" "$1/" > "$tmpf-d1"
  get_dir_info "$sizeopt" "$2/" > "$tmpf-d2"

  diff -w "$tmpf-d1" "$tmpf-d2" > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "@@@ directory $2 doesn't match source ..."
    comm -3 "$tmpf-d1" "$tmpf-d2"
  else
    echo -n '.'
  fi

  rm -f "$tmpf-d1" "$tmpf-d2"

}  #  End of function  print_dir_diffs.


function diff_directories() {
  print_dir_diffs "$1" "$2" "$3"

  ls "$1" | while read fname; do
    [ -d "$1/$fname" ]  &&  diff_directories "$1/$fname" "$2/$fname" "$3"
  done

}  #  End of function  diff_directories.


#
#  main():
#

if [ "$1" = "-s" ]; then
  opts="$1"
  shift
fi

fromdir=${1:-"/tmp"}
todir=${2:-"/tmp"}

diff_directories "$fromdir" "$todir" "$opts"

