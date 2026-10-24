#!/usr/bin/env bash
set -euo pipefail
activity="${1:?activity required}"
grep -q 'MODULE_LICENSE' src/hello_driver.c
case "$activity" in
  lddi-lab-build-load) ;;
  *) echo "unknown activity: $activity" >&2; exit 1 ;;
esac
for symbol in misc_register copy_from_user simple_read_from_buffer module_init module_exit; do
  grep -q "$symbol" src/hello_driver.c || { echo "$activity: missing $symbol" >&2; exit 1; }
done
test -s hello_driver.ko || { echo "$activity: hello_driver.ko was not built" >&2; exit 1; }
echo "$activity: public structural checks passed"
