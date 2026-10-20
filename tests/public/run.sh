#!/usr/bin/env bash
set -euo pipefail
activity="${1:?activity required}"
grep -q 'MODULE_LICENSE' src/qevent.c
case "$activity" in
  ldd1-lab-lifecycle) required='module_init|module_exit' ;;
  ldd1-lab-char-buffer) required='copy_to_user|copy_from_user' ;;
  ldd1-lab-poll-queue) required='wait_event_interruptible|poll_wait' ;;
  ldd1-lab-concurrency) required='mutex_lock|spin_lock|atomic_' ;;
  ldd1-capstone-qevent) required='copy_to_user.*copy_from_user|copy_from_user.*copy_to_user' ;;
  *) echo "unknown activity: $activity" >&2; exit 1 ;;
esac
grep -Eq "$required" src/qevent.c || { echo "$activity: required kernel interfaces are not implemented yet" >&2; exit 1; }
echo "$activity: public structural checks passed"
