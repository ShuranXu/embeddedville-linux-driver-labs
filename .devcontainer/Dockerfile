FROM ubuntu:24.04@sha256:a2d43bffc46670d7108bb3c0468c67c5557c4c92e83e1e34cbff1322ad1b94dc

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    bc bison build-essential ca-certificates cpio curl flex git libelf-dev libglib2.0-dev \
    libncurses-dev libpixman-1-dev libslirp-dev meson ninja-build openssh-client pkg-config \
    python3 python3-venv rsync sparse unzip xz-utils && rm -rf /var/lib/apt/lists/*

ARG QEMU_VERSION=11.1.2
ARG QEMU_SHA256=731b5681e4bb18be313231579b8efd0296c5b015fa36dc533874b639ba838016
RUN curl --fail --location --retry 3 -o /tmp/qemu.tar.xz "https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz" \
 && echo "${QEMU_SHA256}  /tmp/qemu.tar.xz" | sha256sum -c - \
 && tar -C /tmp -xf /tmp/qemu.tar.xz \
 && cd "/tmp/qemu-${QEMU_VERSION}" \
 && ./configure --target-list=x86_64-softmmu --disable-docs --disable-gtk --disable-sdl --disable-vnc \
 && ninja -C build -j2 \
 && ninja -C build install \
 && rm -rf /tmp/qemu*

RUN useradd -m -s /bin/bash vscode && mkdir -p /workspaces /opt/embeddedville && chown -R vscode:vscode /workspaces /opt/embeddedville
USER vscode
