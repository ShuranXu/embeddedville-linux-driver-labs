#!/usr/bin/env bash
set -euo pipefail
activity="${1:?activity required}"
test -f evidence/manifest.json || { echo "evidence manifest missing"; exit 1; }
grep -q 'MODULE_LICENSE' src/qevent.c
if grep -Eq '\b(copy_to_user|copy_from_user|wait_event|poll_wait|mutex_|spin_lock)' src/qevent.c; then
  echo "$activity: public structural checks passed"
else
  echo "$activity: starter still lacks the required kernel interfaces" >&2
  exit 1
fi
