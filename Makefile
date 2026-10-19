obj-m += qevent.o
qevent-objs := src/qevent.o
KDIR ?= /opt/embeddedville/linux-6.18.57
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean || true
