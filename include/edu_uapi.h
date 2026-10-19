#ifndef EMBEDDEDVILLE_EDU_UAPI_H
#define EMBEDDEDVILLE_EDU_UAPI_H
#include <linux/ioctl.h>
#include <linux/types.h>
#define EDU_ABI_VERSION 1U
struct edu_info { __u32 version; __u16 vendor; __u16 device; __u32 irq_mode; __u32 dma_bits; };
struct edu_factorial { __u32 version; __u32 input; __u64 request_id; __u64 result; __s32 status; __u32 reserved; };
struct edu_dma { __u32 version; __u32 length; __u64 user_address; __u64 digest; };
#define EDU_IOC_MAGIC 'E'
#define EDU_IOC_INFO _IOR(EDU_IOC_MAGIC, 1, struct edu_info)
#define EDU_IOC_FACTORIAL _IOWR(EDU_IOC_MAGIC, 2, struct edu_factorial)
#define EDU_IOC_DMA _IOWR(EDU_IOC_MAGIC, 3, struct edu_dma)
#define EDU_IOC_CANCEL _IOW(EDU_IOC_MAGIC, 4, __u64)
#endif
