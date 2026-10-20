#!/usr/bin/env bash
set -euo pipefail
activity="${1:?activity required}"
grep -q 'MODULE_LICENSE' src/edu_driver.c
case "$activity" in
  ldd2-lab-edu-bind) required='pci_register_driver|module_pci_driver' ;;
  ldd2-lab-factorial) required='readl|writel' ;;
  ldd2-lab-irq) required='request_irq|pci_alloc_irq_vectors' ;;
  ldd2-lab-dma) required='dma_set_mask|dma_alloc_coherent|dma_map_' ;;
  ldd2-lab-gpio-sim) required='gpio|gpiod' ;;
  ldd2-lab-i2c-stub) required='i2c|regmap' ;;
  ldd2-capstone-edu) required='pci_register_driver|module_pci_driver' ;;
  *) echo "unknown activity: $activity" >&2; exit 1 ;;
esac
grep -Eq "$required" src/edu_driver.c || { echo "$activity: required kernel interfaces are not implemented yet" >&2; exit 1; }
echo "$activity: public structural checks passed"
