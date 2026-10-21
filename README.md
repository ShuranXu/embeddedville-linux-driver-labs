# Linux Device Drivers: Interfaces and Concurrency

Starter version: `linux-driver-interfaces-v1.1.3`.

This orphan release contains only the Level 1 learner starter and shared public tooling. Start with `./lab doctor`, then use `./lab build`, `./lab run --activity …`, and `./lab test --activity …`. Only `ldd1-capstone-qevent` can be sent to the protected evaluator with `./lab submit --activity ldd1-capstone-qevent`.

The Codespaces image includes the pinned Linux kernel, BusyBox/Dropbear guest, and QEMU runtime. `./lab boot` creates an ephemeral local SSH key and starts the guest; `./lab reset` stops only the tracked guest and preserves learner source and evidence.

QEMU is authoritative; physical hardware is optional and cannot affect completion. QEMU runs with software TCG. Guest SSH is bound to `127.0.0.1:2222` and forwarded privately.

Stopping and restarting a Codespace normally preserves saved files under `/workspaces`. Rebuilds can discard state elsewhere, and deletion or the GitHub retention period can remove unpushed work. Commit or export important work, stop compute when finished, and review account quota and billing.

No solutions, sibling-course files, protected scenarios, credentials, or evaluator secrets belong in this release.
