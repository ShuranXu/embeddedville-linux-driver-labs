FROM ubuntu:24.04@sha256:a2d43bffc46670d7108bb3c0468c67c5557c4c92e83e1e34cbff1322ad1b94dc

ARG DEBIAN_FRONTEND=noninteractive
ARG LINUX_VERSION=6.18.57
ARG LINUX_SHA256=5bd9acdc82ec5efc3790ae840e5aaa40dfde7efff261cf6dde902dc570acf98c
ARG QEMU_VERSION=11.1.2
ARG QEMU_SHA256=731b5681e4bb18be313231579b8efd0296c5b015fa36dc533874b639ba838016
ARG BUSYBOX_VERSION=1.37.0
ARG BUSYBOX_SHA256=3311dff32e746499f4df0d5df04d7eb396382d7e108bb9250e7b519b837043a4
ARG DROPBEAR_VERSION=2026.94
ARG DROPBEAR_SHA256=e098034a843699200c8c977a991fff73159735bf795d5f72ef672c41a6b1ae81

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf automake bc bison build-essential ca-certificates cpio curl file flex git \
    iproute2 jq kmod libelf-dev libglib2.0-dev libncurses-dev libpixman-1-dev libslirp-dev libssl-dev \
    libtool meson musl-tools ninja-build openssh-client pkg-config procps python3 \
    python3-venv rsync shellcheck sparse unzip xz-utils && \
    rm -rf /var/lib/apt/lists/*

COPY runtime /tmp/embeddedville-runtime
RUN /tmp/embeddedville-runtime/build-toolchain.sh kernel
RUN /tmp/embeddedville-runtime/build-toolchain.sh busybox
RUN /tmp/embeddedville-runtime/build-toolchain.sh dropbear
RUN /tmp/embeddedville-runtime/build-toolchain.sh guest
RUN /tmp/embeddedville-runtime/build-toolchain.sh qemu && rm -rf /tmp/embeddedville-runtime

RUN useradd -m -s /bin/bash vscode && \
    mkdir -p /workspaces && \
    chown -R vscode:vscode /workspaces && \
    printf '%s\n' \
      'linux=6.18.57' \
      'qemu=11.1.2' \
      'busybox=1.37.0' \
      'dropbear=2026.94' \
      'acceleration=tcg' > /opt/embeddedville/toolchain-release

USER vscode
WORKDIR /workspaces
