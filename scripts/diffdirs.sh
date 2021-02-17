#!/bin/bash


ndiffs=0


function get_dir_info() {
  local zopt=${1:-""}
  local zdir=${2:-"."}

  # find is 10x slower than ls on a network drive.
  if [ "${zopt}" = "-s" ]; then
    # shellcheck disable=SC2012
    /bin/ls -Fs "${zdir}" | sed 's#\*$##g' | sort -k 2 |  grep -v "^total"
  else
    # shellcheck disable=SC2012
    /bin/ls -F "${zdir}" | sed 's#\*$##g'
  fi

}  #   End of function  get_dir_info.


function print_dir_diffs() {
  local sizeopt=$3
  local tmpf=/tmp/diffdirs.$$

  get_dir_info "${sizeopt}" "$1/" > "${tmpf}-d1"
  get_dir_info "${sizeopt}" "$2/" > "${tmpf}-d2"

  if ! diff -w "${tmpf}-d1" "${tmpf}-d2" > /dev/null 2>&1 ; then
    echo ""
    echo "@@@ directory $2 doesn't match source ..."
    comm -3 "${tmpf}-d1" "${tmpf}-d2"
    ndiffs=$((ndiffs + 1))
    echo ""
    echo -n "# "
  else
    echo -n '.'
  fi

  rm -f "${tmpf}-d1" "${tmpf}-d2"

}  #  End of function  print_dir_diffs.


function diff_directories() {
  [ -e "$2" ]  ||  return ${ndiffs}

  print_dir_diffs "$1" "$2" "$3"

  [ -d "$2" ]  ||  return ${ndiffs}

  while read -r fname; do
    if [ -d "$1/${fname}" ]; then
      diff_directories "$1/${fname}" "$2/${fname}" "$3"
    fi
  done < <(/bin/ls "$1")

  return ${ndiffs}

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
