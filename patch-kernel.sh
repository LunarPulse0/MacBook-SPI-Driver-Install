#!/bin/bash

set -e

# Check for sudo/root
if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo or as root."
  exit 1
fi

OLD_KERNEL="6.1.0-10-amd64"  # Change this to the kernel version you want to downgrade to
OLD_KERNEL_HEADER="linux-headers-$OLD_KERNEL"
OLD_KERNEL_IMAGE="linux-image-$OLD_KERNEL"

echo "Current kernel: $(uname -r)"
echo "Target kernel downgrade version: $OLD_KERNEL"
echo

read -rp "This script will install the older kernel $OLD_KERNEL alongside current kernel and set it as default in GRUB. Continue? [y/N]: " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "Aborted by user."
  exit 0
fi

echo "Updating package list..."
apt-get update

echo "Installing kernel image and headers for $OLD_KERNEL ..."
apt-get install -y $OLD_KERNEL_IMAGE $OLD_KERNEL_HEADER

echo "Kernel $OLD_KERNEL installed."

echo "Updating GRUB bootloader to default to $OLD_KERNEL ..."

# Find the GRUB menu entry for the kernel
GRUB_ENTRY=$(grep -P "^menuentry '.*$OLD_KERNEL'" /boot/grub/grub.cfg | head -n1 | cut -d"'" -f2)

if [ -z "$GRUB_ENTRY" ]; then
  echo "ERROR: Could not find GRUB entry for kernel $OLD_KERNEL"
  exit 1
fi

echo "Found GRUB menu entry: $GRUB_ENTRY"

# Set grub default to this kernel
grub-set-default "$GRUB_ENTRY"

echo "Running update-grub..."
update-grub

echo "Done! Your system will boot into kernel $OLD_KERNEL by default on next reboot."

echo
echo "IMPORTANT:"
echo "- Your current kernel is still installed, so you can select it manually in GRUB if needed."
echo "- To revert default kernel, run: sudo grub-set-default 0"
echo "- Always keep a live USB handy in case of boot issues."
echo "- After reboot, check kernel version with: uname -r"
echo
read -rp "Reboot now? [y/N]: " reboot_confirm
if [[ $reboot_confirm =~ ^[Yy]$ ]]; then
  reboot
else
  echo "Reboot manually later to apply the new kernel."
fi
