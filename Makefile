obj-m += edu_driver.o
edu_driver-objs := src/edu_driver.o
KDIR ?= /opt/embeddedville/linux-6.18.57
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean || true
