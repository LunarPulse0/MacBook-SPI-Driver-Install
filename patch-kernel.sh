#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

info() { echo -e "${BLUE}[ # ]${RESET} $*"; }
success() { echo -e "${GREEN}[ + ]${RESET} $*"; }
error() { echo -e "${RED}[ - ]${RESET} $*"; }

if [ "$EUID" -ne 0 ]; then
  error "Please run this script with sudo or as root."
  exit 1
fi

current_kernel=$(uname -r)
info "Current kernel version: $current_kernel"

info "Searching for installed kernels (excluding current)..."

installed_kernels=($(dpkg --list | grep linux-image | awk '{print $2}' | grep -v "$current_kernel"))

if [ ${#installed_kernels[@]} -eq 0 ]; then
  info "No other installed kernels found."
  read -rp "Enter the exact kernel package to install (e.g. linux-image-6.1.0-kali9-amd64): " OLD_KERNEL
else
  info "Installed kernels found:"
  for i in "${!installed_kernels[@]}"; do
    echo "  $i) ${installed_kernels[$i]}"
  done
  read -rp "Select the kernel to boot by default (enter number): " choice
  OLD_KERNEL=${installed_kernels[$choice]}
fi

if [ -z "$OLD_KERNEL" ]; then
  error "No kernel selected. Aborting."
  exit 1
fi

info "You selected kernel package: $OLD_KERNEL"

# Check if selected kernel package is installed
if ! dpkg -s "$OLD_KERNEL" &>/dev/null; then
  info "Kernel package $OLD_KERNEL not installed. Installing..."
  apt-get update
  apt-get install -y "$OLD_KERNEL"
fi

# Extract version string from package name
# Example: linux-image-6.12.13-amd64  ->  6.12.13-amd64
kernel_version=${OLD_KERNEL#linux-image-}

info "Looking for GRUB menuentry matching kernel version: $kernel_version"

# GRUB entries are usually like:
# menuentry 'Debian GNU/Linux, with Linux 6.12.13-amd64' ...
# We'll grep for the kernel version string

GRUB_ENTRY=$(grep -P "^menuentry '.*${kernel_version//./\\.}.*'" /boot/grub/grub.cfg | head -n1 | cut -d"'" -f2 || true)

if [ -z "$GRUB_ENTRY" ]; then
  error "Could not find a GRUB entry for kernel version '$kernel_version'."
  error "Please check /boot/grub/grub.cfg and set default manually."
  exit 1
fi

success "Found GRUB entry: $GRUB_ENTRY"

info "Setting GRUB default entry..."

grub-set-default "$GRUB_ENTRY"
update-grub

success "GRUB default set to kernel: $kernel_version"

read -rp "Reboot now? (y/N): " reboot_confirm
if [[ "$reboot_confirm" =~ ^[Yy]$ ]]; then
  info "Rebooting now..."
  reboot
else
  info "Reboot manually later to use the selected kernel."
fi
