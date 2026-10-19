// SPDX-License-Identifier: GPL-2.0-only
#include <linux/cdev.h>
#include <linux/completion.h>
#include <linux/dma-mapping.h>
#include <linux/interrupt.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/poll.h>
#include <linux/uaccess.h>
#include "../include/edu_uapi.h"

#define EDU_VENDOR_ID 0x1234
#define EDU_DEVICE_ID 0x11e8
#define EDU_BAR 0

struct edu_device { struct pci_dev *pdev; void __iomem *bar0; struct completion completed; bool removing; };
static const struct pci_device_id edu_ids[] = { { PCI_DEVICE(EDU_VENDOR_ID, EDU_DEVICE_ID) }, { } };
MODULE_DEVICE_TABLE(pci, edu_ids);

/* Learner starter: implement resource validation, UAPI, IRQ, DMA, and removal TODOs. */
static int edu_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
    dev_info(&pdev->dev, "EDU starter matched; implement probe ownership TODOs\n");
    return -EOPNOTSUPP;
}
static void edu_remove(struct pci_dev *pdev) { dev_info(&pdev->dev, "EDU starter remove\n"); }
static struct pci_driver edu_driver = { .name="embeddedville_edu", .id_table=edu_ids, .probe=edu_probe, .remove=edu_remove };
module_pci_driver(edu_driver);
MODULE_LICENSE("GPL"); MODULE_DESCRIPTION("EmbeddedVille QEMU EDU learner starter");
