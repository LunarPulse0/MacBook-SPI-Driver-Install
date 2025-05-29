#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ASCII Art Logo
logo() {
  clear
  echo -e "${CYAN}"
  echo "                           @@@@                "
  echo "                         @@@@@@                "
  echo "                        @@@@@@                 "
  echo "                       @@@@@@                  "
  echo "                 @@@   @@@@%@@@@               "
  echo "             @@@@@@@@@@%@@@@@@@@@@@@           "
  echo "           @@@@@@@@@@@@@@@@@@@@@@@@@@          "
  echo "          @@@@@@@@@@@@@@@@@@@@@@@@@@           "
  echo "         #@@@@@@@@@@@@@@@@@@@@@@@@             "
  echo "         @@@@@@@@@@@@@@@@@@@@@@@@#             "
  echo "         @@@@@@@@@@@@@@@@@@@@@@@@%             "
  echo "         @@@@@@@@@@@@@@@@@@@@@@@@@             "
  echo "          @@@@@@@@@@@@@@@@@@@@@@@@@@           "
  echo "          @@@@@@@@@@@@@@@@@@@@@@@@@@@%         "
  echo "          @@@@@@@@@@@@@@@@@@@@@@@@@@@@         "
  echo "           @@@@@@@@@@@@@@@@@@@@@@@@@@          "
  echo "             @@@@@@@@@@@@@@@@@@@@@@@           "
  echo "              @@@@@@@@@@@@@@@@@@@@             "
  echo "                @@@@@@    @@@@@@@              "
  echo -e "${RESET}"
  echo -e "${GREEN}Welcome to MACFIX - MacBook SPI Driver Installer${RESET}"
  echo
}

# Show loading bar with timer
loading_bar() {
  local duration=$1
  local interval=0.1
  local steps=$(echo "$duration / $interval" | bc)
  local i=0
  echo -ne "["
  while (( $(echo "$i < $steps" | bc -l) )); do
    echo -ne "#"
    sleep $interval
    ((i++))
  done
  echo "]"
}

# Detect kernel version
detect_kernel() {
  local kernel_ver
  kernel_ver=$(uname -r 2>/dev/null)
  if [[ -z "$kernel_ver" ]]; then
    echo -e "${YELLOW}Could not auto-detect kernel version.${RESET}"
    read -rp "$(echo -e ${YELLOW}Please enter your kernel version (e.g. 6.12.25-amd64): ${RESET})" kernel_ver
  else
    echo -e "${GREEN}Detected kernel version: $kernel_ver${RESET}"
  fi
  echo "$kernel_ver"
}

# Check for required packages
check_requirements() {
  echo -e "${BLUE}Checking required packages...${RESET}"
  local missing=0
  for pkg in build-essential linux-headers-$(uname -r) dkms; do
    if ! dpkg -s "$pkg" &> /dev/null; then
      echo -e "${YELLOW}Package $pkg is not installed. Installing...${RESET}"
      sudo apt-get update
      sudo apt-get install -y "$pkg"
      if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to install $pkg. Please install it manually and rerun.${RESET}"
        missing=1
      fi
    fi
  done

  if [[ $missing -eq 1 ]]; then
    echo -e "${RED}Some packages failed to install. Exiting.${RESET}"
    exit 1
  fi
}

# Build driver
build_driver() {
  local kernel_ver="$1"
  echo -e "${BLUE}Building driver for kernel $kernel_ver...${RESET}"

  if [[ ! -d "/lib/modules/$kernel_ver/build" ]]; then
    echo -e "${YELLOW}Kernel headers not found at /lib/modules/$kernel_ver/build.${RESET}"
    echo -e "${YELLOW}Trying to install kernel headers...${RESET}"
    sudo apt-get update
    sudo apt-get install -y linux-headers-"$kernel_ver"
    if [[ $? -ne 0 ]]; then
      echo -e "${RED}Failed to install kernel headers. Please install them manually.${RESET}"
      exit 1
    fi
  fi

  echo -e "${CYAN}Running make...${RESET}"
  sudo make -C /lib/modules/"$kernel_ver"/build M="$PWD" modules

  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Build failed!${RESET}"
    exit 1
  fi

  echo -e "${GREEN}Build succeeded.${RESET}"
}

# Install driver using DKMS
install_driver() {
  echo -e "${BLUE}Installing driver with DKMS...${RESET}"

  # Copy driver source to /usr/src/macfix-1.0
  sudo rm -rf /usr/src/macfix-1.0
  sudo mkdir -p /usr/src/macfix-1.0
  sudo cp -r ./* /usr/src/macfix-1.0

  # Add module to DKMS
  sudo dkms remove -m macfix -v 1.0 --all 2>/dev/null
  sudo dkms add -m macfix -v 1.0
  sudo dkms build -m macfix -v 1.0
  sudo dkms install -m macfix -v 1.0

  if [[ $? -ne 0 ]]; then
    echo -e "${RED}DKMS install failed!${RESET}"
    exit 1
  fi

  echo -e "${GREEN}Driver installed successfully via DKMS.${RESET}"
}

# Main installer flow
main() {
  logo

  echo -e "${YELLOW}Press Ctrl+C anytime to abort.${RESET}"
  sleep 1

  kernel_ver=$(detect_kernel)

  check_requirements

  echo -e "${YELLOW}Ready to build and install the driver for kernel version ${kernel_ver}${RESET}"
  read -rp "$(echo -e ${YELLOW}Proceed? (y/n): ${RESET})" confirm
  if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation aborted.${RESET}"
    exit 0
  fi

  echo -e "${CYAN}Starting build...${RESET}"
  loading_bar 3

  build_driver "$kernel_ver"

  echo -e "${CYAN}Starting installation...${RESET}"
  loading_bar 3

  install_driver

  echo -e "${GREEN}MACFIX installation complete! Reboot your system to load the driver.${RESET}"
}

main
