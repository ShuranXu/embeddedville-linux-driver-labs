// SPDX-License-Identifier: GPL-2.0-only
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/uaccess.h>

#define HELLO_INPUT_MAX 32

static ssize_t hello_read(struct file *file, char __user *buffer,
                          size_t count, loff_t *offset)
{
    static const char message[] = "hello from the kernel\n";

    return simple_read_from_buffer(buffer, count, offset, message,
                                   sizeof(message) - 1);
}

static ssize_t hello_write(struct file *file, const char __user *buffer,
                           size_t count, loff_t *offset)
{
    char input[HELLO_INPUT_MAX + 1];
    size_t accepted = min(count, (size_t)HELLO_INPUT_MAX);

    if (copy_from_user(input, buffer, accepted))
        return -EFAULT;

    input[accepted] = '\0';
    pr_info("hello_driver: received %zu byte(s): %s\n", accepted, input);
    return accepted;
}

static const struct file_operations hello_fops = {
    .owner = THIS_MODULE,
    .read = hello_read,
    .write = hello_write,
};

static struct miscdevice hello_device = {
    .minor = MISC_DYNAMIC_MINOR,
    .name = "hello_driver",
    .fops = &hello_fops,
    .mode = 0600,
};

static int __init hello_init(void)
{
    int result = misc_register(&hello_device);

    if (result)
        return result;
    pr_info("hello_driver: loaded; node=/dev/%s\n", hello_device.name);
    return 0;
}

static void __exit hello_exit(void)
{
    misc_deregister(&hello_device);
    pr_info("hello_driver: unloaded\n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("EmbeddedVille");
MODULE_DESCRIPTION("Beginner character-driver walkthrough for browser-hosted QEMU");
