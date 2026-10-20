#!/usr/bin/env bash
set -euo pipefail

download() {
  local url="$1" output="$2" digest="$3"
  curl --fail --location --retry 3 --output "$output" "$url"
  printf '%s  %s\n' "$digest" "$output" | sha256sum -c -
}

jobs="${BUILD_JOBS:-$(nproc)}"
install_root=/opt/embeddedville
guest_root="$install_root/guest/rootfs"
mkdir -p "$install_root" "$guest_root"

download "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${LINUX_VERSION}.tar.xz" /tmp/linux.tar.xz "$LINUX_SHA256"
tar -C /opt/embeddedville -xf /tmp/linux.tar.xz
kernel="$install_root/linux-${LINUX_VERSION}"
make -C "$kernel" defconfig
while IFS='=' read -r symbol value; do
  case "$symbol" in
    CONFIG_*)
      case "$value" in
        y) "$kernel/scripts/config" --file "$kernel/.config" --enable "${symbol#CONFIG_}" ;;
        m) "$kernel/scripts/config" --file "$kernel/.config" --module "${symbol#CONFIG_}" ;;
      esac
      ;;
  esac
done < /tmp/embeddedville-runtime/linux.config
make -C "$kernel" olddefconfig
make -C "$kernel" -j"$jobs" bzImage modules
make -C "$kernel" modules_install INSTALL_MOD_PATH="$guest_root"
cp "$kernel/arch/x86/boot/bzImage" "$install_root/guest/bzImage"

download "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2" /tmp/busybox.tar.bz2 "$BUSYBOX_SHA256"
tar -C /tmp -xf /tmp/busybox.tar.bz2
busybox="/tmp/busybox-${BUSYBOX_VERSION}"
make -C "$busybox" defconfig
sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' "$busybox/.config"
make -C "$busybox" -j"$jobs" CC=musl-gcc
make -C "$busybox" CC=musl-gcc CONFIG_PREFIX="$guest_root" install

download "https://matt.ucc.asn.au/dropbear/releases/dropbear-${DROPBEAR_VERSION}.tar.bz2" /tmp/dropbear.tar.bz2 "$DROPBEAR_SHA256"
tar -C /tmp -xf /tmp/dropbear.tar.bz2
dropbear="/tmp/dropbear-${DROPBEAR_VERSION}"
(
  cd "$dropbear"
  CC=musl-gcc CFLAGS='-Os' LDFLAGS='-static' ./configure --disable-zlib --disable-lastlog --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx
  make -j"$jobs" PROGRAMS="dropbear dropbearkey"
)
install -D -m 0755 "$dropbear/dropbear" "$guest_root/usr/sbin/dropbear"
install -D -m 0755 "$dropbear/dropbearkey" "$guest_root/usr/bin/dropbearkey"

install -D -m 0755 /tmp/embeddedville-runtime/init "$guest_root/init"
mkdir -p "$guest_root"/{dev,proc,sys,tmp,run,root/.ssh,etc/dropbear,workspace}
chmod 1777 "$guest_root/tmp"
printf 'root:x:0:0:root:/root:/bin/sh\n' > "$guest_root/etc/passwd"
printf 'root:x:0:\n' > "$guest_root/etc/group"
printf 'nameserver 10.0.2.3\n' > "$guest_root/etc/resolv.conf"
depmod -b "$guest_root" "$LINUX_VERSION"
(
  cd "$guest_root"
  find . -print0 | cpio --null -o --format=newc | gzip -9 > "$install_root/guest/initramfs.cpio.gz"
)

download "https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz" /tmp/qemu.tar.xz "$QEMU_SHA256"
tar -C /tmp -xf /tmp/qemu.tar.xz
qemu="/tmp/qemu-${QEMU_VERSION}"
(
  cd "$qemu"
  ./configure --target-list=x86_64-softmmu --disable-docs --disable-gtk --disable-sdl --disable-vnc --disable-werror
  ninja -C build -j"$jobs"
  ninja -C build install
)

rm -rf /tmp/linux.tar.xz /tmp/busybox* /tmp/dropbear* /tmp/qemu*
