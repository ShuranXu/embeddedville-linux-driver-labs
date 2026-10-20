#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
state="$root/.lab-state"
kernel=/opt/embeddedville/guest/bzImage
initramfs=/opt/embeddedville/guest/initramfs.cpio.gz
port="${EMBEDDEDVILLE_GUEST_SSH_PORT:-2222}"

mkdir -p "$state"
if [[ -s "$state/qemu.pid" ]]; then
  pid="$(cat "$state/qemu.pid")"
  if kill -0 "$pid" 2>/dev/null; then
    echo "QEMU guest already running (pid $pid)."
    exit 0
  fi
  rm -f "$state/qemu.pid"
fi

[[ -s "$kernel" && -s "$initramfs" ]] || { echo "Pinned guest artifacts are missing." >&2; exit 1; }
if [[ ! -s "$state/id_ed25519" ]]; then
  ssh-keygen -q -t ed25519 -N '' -C embeddedville-lab -f "$state/id_ed25519"
fi
cp "$state/id_ed25519.pub" "$state/guest_authorized_keys"
chmod 600 "$state/id_ed25519" "$state/guest_authorized_keys"

course_id="$(cd "$root" && python3 -c 'import json; print(json.load(open(".embeddedville-workspace.json"))["courseId"])')"
device=()
[[ "$course_id" == "linux-device-drivers-hardware" ]] && device=(-device edu)

qemu-system-x86_64 \
  -accel tcg,thread=multi \
  -machine q35 \
  -cpu max \
  -smp 2 \
  -m 2048 \
  -kernel "$kernel" \
  -initrd "$initramfs" \
  -append "console=ttyS0 panic=-1 oops=panic nokaslr" \
  -fsdev local,id=workspace,path="$root",security_model=none \
  -device virtio-9p-pci,fsdev=workspace,mount_tag=workspace \
  -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:${port}-:22" \
  -device virtio-net-pci,netdev=net0 \
  "${device[@]}" \
  -display none \
  -serial "file:$state/serial.log" \
  -monitor none \
  -no-reboot \
  </dev/null >"$state/qemu.log" 2>&1 &
pid=$!
printf '%s\n' "$pid" > "$state/qemu.pid"
printf '%s\n' "$course_id" > "$state/course-id"

ssh_opts=(-i "$state/id_ed25519" -p "$port" -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=2)
for _ in $(seq 1 90); do
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "QEMU exited before SSH became ready." >&2
    tail -n 100 "$state/serial.log" >&2 || true
    exit 1
  fi
  if ssh "${ssh_opts[@]}" root@127.0.0.1 'test "$(uname -r)" = 6.18.57' >/dev/null 2>&1; then
    echo "QEMU guest ready on 127.0.0.1:${port} using TCG."
    exit 0
  fi
  sleep 1
done

echo "Timed out waiting for QEMU guest SSH." >&2
tail -n 100 "$state/serial.log" >&2 || true
exit 1
