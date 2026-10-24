# Introduction to Linux Device Drivers — guided lab

Starter version: `linux-driver-introduction-v1.0.0`.

This release contains the complete, intentionally small `hello_driver.c` used by the beginner code walkthrough. Start with `./lab doctor`, then run:

```bash
./lab build --activity lddi-lab-build-load
./lab run --activity lddi-lab-build-load
./lab test --activity lddi-lab-build-load
./lab reset
```

The activity builds `hello_driver.ko`, boots a pinned Linux 6.18.57 guest under QEMU 11.1.2 software TCG, loads the module, exercises `/dev/hello_driver`, checks the correlated kernel log, and unloads it. It is formative and is never submitted for course completion.

The Codespaces image includes the pinned Linux kernel, BusyBox/Dropbear guest, and QEMU runtime. `./lab boot` creates an ephemeral local SSH key and starts the guest; `./lab reset` stops only the tracked guest and preserves learner source and evidence.

QEMU is authoritative; physical hardware is optional and cannot affect completion. QEMU runs with software TCG. Guest SSH is bound to `127.0.0.1:2222` and forwarded privately.

Stopping and restarting a Codespace normally preserves saved files under `/workspaces`. Rebuilds can discard state elsewhere, and deletion or the GitHub retention period can remove unpushed work. Commit or export important work, stop compute when finished, and review account quota and billing.

No local build is required. No protected scenarios, credentials, evaluator secrets, or completion submission belong in this release.
