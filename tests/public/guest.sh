#!/bin/sh
set -eu

course_id="${1:?course id required}"
activity="${2:?activity required}"
mode="${3:-direct}"
cd /workspace
dmesg -c >/dev/null 2>&1 || true

case "$course_id" in
  linux-device-drivers-introduction)
    rmmod hello_driver 2>/dev/null || true
    case "$mode" in
      direct)
        insmod ./hello_driver.ko
        unload() { rmmod hello_driver; }
        ;;
      install)
        module_dir="/lib/modules/$(uname -r)/extra"
        module_path="$module_dir/hello_driver.ko"
        cleanup_install() {
          modprobe -r hello_driver 2>/dev/null || true
          rm -f "$module_path"
          depmod -a
        }
        trap cleanup_install EXIT INT TERM
        mkdir -p "$module_dir"
        cp ./hello_driver.ko "$module_path"
        chmod 0644 "$module_path"
        depmod -a
        grep -q 'extra/hello_driver.ko' "/lib/modules/$(uname -r)/modules.dep"
        modprobe hello_driver
        unload() { modprobe -r hello_driver; }
        ;;
      *) echo "unsupported introduction mode: $mode" >&2; exit 1 ;;
    esac
    test -d /sys/module/hello_driver
    test -c /dev/hello_driver
    test "$(cat /dev/hello_driver)" = "hello from the kernel"
    printf learner > /dev/hello_driver
    dmesg | grep -q 'hello_driver: received 7 byte(s): learner'
    unload
    test ! -e /dev/hello_driver
    dmesg | grep -q 'hello_driver: unloaded'
    if [ "$mode" = install ]; then
      rm -f "$module_path"
      depmod -a
      ! grep -q 'extra/hello_driver.ko' "/lib/modules/$(uname -r)/modules.dep"
      trap - EXIT INT TERM
    fi
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
echo "$activity: guest $mode load/unload checks passed"
