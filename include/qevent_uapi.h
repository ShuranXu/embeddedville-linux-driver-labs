#ifndef QEVENT_UAPI_H
#define QEVENT_UAPI_H
#include <linux/ioctl.h>
#include <linux/types.h>
#define QEVENT_ABI_VERSION 1U
struct qevent_config { __u32 version; __u32 capacity; __u32 flags; __u32 reserved; };
struct qevent_stats { __u32 version; __u32 reserved; __u64 enqueued; __u64 dropped; __u64 cancelled; };
#define QEVENT_IOC_MAGIC 'Q'
#define QEVENT_IOC_CONFIG _IOW(QEVENT_IOC_MAGIC, 1, struct qevent_config)
#define QEVENT_IOC_STATS _IOR(QEVENT_IOC_MAGIC, 2, struct qevent_stats)
#define QEVENT_IOC_CANCEL _IO(QEVENT_IOC_MAGIC, 3)
#endif
