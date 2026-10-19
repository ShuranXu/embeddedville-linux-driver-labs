#!/usr/bin/env bash
set -euo pipefail
activity="${1:?activity required}"
test -f evidence/manifest.json || { echo "evidence manifest missing"; exit 1; }
grep -q 'MODULE_LICENSE' src/edu_driver.c
if grep -Eq '\b(pci_register_driver|pci_iomap|readl|writel|dma_set_mask|request_irq|pci_alloc_irq_vectors)' src/edu_driver.c; then
  echo "$activity: public structural checks passed"
else
  echo "$activity: starter still lacks the required kernel interfaces" >&2
  exit 1
fi
