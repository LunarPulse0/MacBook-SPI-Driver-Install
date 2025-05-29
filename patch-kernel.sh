#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo or as root."
  exit 1
fi

current_kernel=$(uname -r)
echo "Current kernel version: $current_kernel"

echo "Searching for installed kernels older than current..."

# List installed kernels except current
installed_kernels=($(dpkg --list | grep linux-image | awk '{print $2}' | grep -v "$current_kernel"))

if [ ${#installed_kernels[@]} -eq 0 ]; then
  echo "No other installed kernels found. Please enter the kernel version you want to install (e.g. 6.1.0-kali9-amd64):"
  read -rp "Kernel version: " OLD_KERNEL
else
  echo "Installed kernels:"
  for i in "${!installed_kernels[@]}"; do
    echo "$i) ${installed_kernels[$i]}"
  done
  read -rp "Select the kernel to boot by default (enter number): " choice
  OLD_KERNEL=${installed_kernels[$choice]}
fi

if [ -z "$OLD_KERNEL" ]; then
  echo "No kernel selected, aborting."
  exit 1
fi

echo "You selected kernel: $OLD_KERNEL"

# Check if kernel package installed, if not install it
if ! dpkg -s "$OLD_KERNEL" >/dev/null 2>&1; then
  echo "Kernel package $OLD_KERNEL is not installed. Installing..."
  apt-get update
  apt-get install -y "$OLD_KERNEL"
fi

# Find GRUB entry for selected kernel
GRUB_ENTRY=$(grep -P "^menuentry '.*${OLD_KERNEL}.*'" /boot/grub/grub.cfg | head -n1 | cut -d"'" -f2)

if [ -z "$GRUB_ENTRY" ]; then
  echo "ERROR: Could not find GRUB entry for kernel $OLD_KERNEL"
  exit 1
fi

echo "Setting GRUB default to: $GRUB_ENTRY"
grub-set-default "$GRUB_ENTRY"
update-grub

echo "Done! Your system will boot into kernel $OLD_KERNEL by default on next reboot."

read -rp "Reboot now? (y/N): " reboot_confirm
if [[ "$reboot_confirm" =~ ^[Yy]$ ]]; then
  reboot
else
  echo "Reboot manually later."
fi
