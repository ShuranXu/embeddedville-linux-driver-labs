obj-m += hello_driver.o
hello_driver-objs := src/hello_driver.o
KDIR ?= /opt/embeddedville/linux-6.18.57
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean || true
