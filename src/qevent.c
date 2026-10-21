// SPDX-License-Identifier: GPL-2.0-only
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/module.h>
#include <linux/poll.h>
#include <linux/uaccess.h>
#include <linux/wait.h>
#include "../include/qevent_uapi.h"

/* Learner starter: keep the UAPI stable and implement the TODOs. */
static int qevent_open(struct inode *inode, struct file *file) { return -EOPNOTSUPP; }
static int qevent_release(struct inode *inode, struct file *file) { return 0; }
static ssize_t qevent_read(struct file *file, char __user *buffer, size_t count, loff_t *offset) { return -EOPNOTSUPP; }
static ssize_t qevent_write(struct file *file, const char __user *buffer, size_t count, loff_t *offset) { return -EOPNOTSUPP; }
static __poll_t qevent_poll(struct file *file, poll_table *wait) { return EPOLLERR; }
static long qevent_ioctl(struct file *file, unsigned int command, unsigned long argument) { return -ENOTTY; }
static const struct file_operations qevent_fops __maybe_unused = { .owner=THIS_MODULE, .open=qevent_open, .release=qevent_release, .read=qevent_read, .write=qevent_write, .poll=qevent_poll, .unlocked_ioctl=qevent_ioctl };
static int __init qevent_init(void) { pr_info("qevent: starter loaded; implement lifecycle TODOs\n"); return 0; }
static void __exit qevent_exit(void) { pr_info("qevent: starter unloaded\n"); }
module_init(qevent_init); module_exit(qevent_exit);
MODULE_LICENSE("GPL"); MODULE_DESCRIPTION("EmbeddedVille QEvent learner starter");
