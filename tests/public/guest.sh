#!/bin/sh
set -eu

course_id="${1:?course id required}"
activity="${2:?activity required}"
cd /workspace
dmesg -c >/dev/null 2>&1 || true

case "$course_id" in
  linux-device-drivers-introduction)
    rmmod hello_driver 2>/dev/null || true
    insmod ./hello_driver.ko
    test -d /sys/module/hello_driver
    test -c /dev/hello_driver
    test "$(cat /dev/hello_driver)" = "hello from the kernel"
    printf learner > /dev/hello_driver
    dmesg | grep -q 'hello_driver: received 7 byte(s): learner'
    rmmod hello_driver
    test ! -e /dev/hello_driver
    dmesg | grep -q 'hello_driver: unloaded'
    ;;
  linux-device-drivers-interfaces)
    rmmod qevent 2>/dev/null || true
    insmod ./qevent.ko
    test -d /sys/module/qevent
    if [ -e /dev/qevent0 ]; then
      dd if=/dev/qevent0 of=/dev/null bs=1 count=0 2>/dev/null || true
    fi
    rmmod qevent
    ;;
  linux-device-drivers-hardware)
    rmmod edu_driver 2>/dev/null || true
    test -n "$(grep -l '^0x1234$' /sys/bus/pci/devices/*/vendor 2>/dev/null | head -n 1)"
    insmod ./edu_driver.ko
    test -d /sys/module/edu_driver
    rmmod edu_driver
    ;;
  *) echo "unsupported course: $course_id" >&2; exit 1 ;;
esac

log="$(dmesg 2>/dev/null || true)"
if printf '%s\n' "$log" | grep -Eiq 'BUG:|WARNING:|KASAN:|UBSAN:|kernel panic|possible circular locking dependency|INFO: task .* blocked'; then
  printf '%s\n' "$log" >&2
  exit 1
fi
echo "$activity: guest load/unload checks passed"
