# Kernel module targets
obj-m := applespi.o apple-ibridge.o apple-ib-tb.o apple-ib-als.o

# Optional: Add extra include paths (e.g., for tracing support)
ccflags-y := -I$(src)

# Kernel version handling
KVERSION := $(KERNELRELEASE)
ifeq ($(KVERSION),)
    KVERSION := $(shell uname -r)
endif

KDIR := /lib/modules/$(KVERSION)/build
PWD := $(shell pwd)

# Default build target
all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

# Clean up build artifacts
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

# (Optional) Test: remove and insert applespi module
test: all
	@sync
	@echo "Removing existing applespi module (ignore errors)..."
	@-sudo rmmod applespi
	@echo "Inserting new applespi module..."
	@sudo insmod ./applespi.ko

