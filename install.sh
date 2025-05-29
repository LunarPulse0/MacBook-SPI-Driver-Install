#!/bin/bash

# Clear screen
clear

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Timer utilities
timer_start() { TIMER_START=$(date +%s); }
timer_end() {
    TIMER_END=$(date +%s)
    DIFF=$((TIMER_END - TIMER_START))
    echo -e "${MAGENTA}⏱️  Duration: ${DIFF}s${RESET}"
}

# Fake progress bar
progress_bar() {
    echo -ne "${1} ["
    for i in $(seq 1 30); do
        echo -ne "#"
        sleep 0.03
    done
    echo -e "] Done!${RESET}"
}

# ASCII Art
echo -e "${CYAN}"
cat << "EOF"
                           
                           @@@@                
                         @@@@@@                
                        @@@@@@                 
                       @@@@@@                  
                 @@@   @@@@%@@@@               
             @@@@@@@@@@%@@@@@@@@@@@@           
           @@@@@@@@@@@@@@@@@@@@@@@@@@          
          @@@@@@@@@@@@@@@@@@@@@@@@@@           
         #@@@@@@@@@@@@@@@@@@@@@@@@             
         @@@@@@@@@@@@@@@@@@@@@@@@#             
         @@@@@@@@@@@@@@@@@@@@@@@@%             
         @@@@@@@@@@@@@@@@@@@@@@@@@             
          @@@@@@@@@@@@@@@@@@@@@@@@@@           
          @@@@@@@@@@@@@@@@@@@@@@@@@@@%         
          @@@@@@@@@@@@@@@@@@@@@@@@@@@@         
           @@@@@@@@@@@@@@@@@@@@@@@@@@          
             @@@@@@@@@@@@@@@@@@@@@@@           
              @@@@@@@@@@@@@@@@@@@@             
                @@@@@@    @@@@@@@              
EOF
echo -e "${RESET}${YELLOW}MACFIX – MacBook Linux Driver Installer${RESET}\n"

# Intro
echo -e "${GREEN}This script will compile and install drivers for your MacBook:${RESET}"
echo -e "${CYAN}- Trackpad\n- Keyboard\n- Ambient Light Sensor${RESET}\n"
echo -e "${BLUE}All required source files detected in current directory.${RESET}\n"

# Confirm
echo -e "${YELLOW}Ready to install? (y/n): ${RESET}"
read confirm
if [[ "$confirm" != "y" ]]; then
    echo -e "${RED}Installation cancelled.${RESET}"
    exit 1
fi

# Check required tools
echo -e "\n${BLUE}Checking required tools...${RESET}"
missing=false
for cmd in make dkms gcc; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${RED}  ✘ $cmd not found${RESET}"
        missing=true
    else
        echo -e "${GREEN}  ✔ $cmd found${RESET}"
    fi
done
if [ "$missing" = true ]; then
    echo -e "${RED}Please install the missing tools and re-run MACFIX.${RESET}"
    exit 1
fi

# Detect kernel version
KERNEL_VER=$(uname -r)
HEADER_PATH="/lib/modules/$KERNEL_VER/build"
echo -e "\n${BLUE}🔍 Checking kernel headers for: $KERNEL_VER${RESET}"

# Try to install if not found
if [ ! -d "$HEADER_PATH" ]; then
    echo -e "${RED}✘ Kernel headers not found for $KERNEL_VER${RESET}"
    echo -e "${YELLOW}Attempting to install headers with apt...${RESET}"
    sudo apt update
    sudo apt install -y "linux-headers-$KERNEL_VER"
    sleep 2
fi

# Retry check
if [ ! -d "$HEADER_PATH" ]; then
    echo -e "${RED}Still missing. Enter kernel version manually (e.g., 6.5.0-17-generic):${RESET}"
    read -p "> " MANUAL_VER
    HEADER_PATH="/lib/modules/$MANUAL_VER/build"
    if [ ! -d "$HEADER_PATH" ]; then
        echo -e "${RED}✘ Kernel headers not found. Please install manually and try again.${RESET}"
        exit 1
    else
        echo -e "${GREEN}✔ Found headers for $MANUAL_VER${RESET}"
    fi
else
    echo -e "${GREEN}✔ Kernel headers installed${RESET}"
fi

# Compile
echo -e "\n${YELLOW}🔧 Compiling drivers...${RESET}"
timer_start
progress_bar "${CYAN}  Building source"
if sudo make -C "$HEADER_PATH" M=$(pwd) modules; then
    timer_end
    echo -e "${GREEN}✔ Compilation successful${RESET}"
else
    echo -e "${RED}✘ Build failed. Check errors above.${RESET}"
    exit 1
fi

# DKMS install
echo -e "\n${YELLOW}📦 Installing with DKMS...${RESET}"
timer_start
progress_bar "${CYAN}  Installing module"
sudo dkms remove -m applespi -v 0.1 --all &>/dev/null
sudo dkms add .
sudo dkms build -m applespi -v 0.1
sudo dkms install -m applespi -v 0.1

if [ $? -eq 0 ]; then
    timer_end
    echo -e "${GREEN}✔ DKMS install successful${RESET}"
else
    echo -e "${RED}✘ DKMS failed. Check logs above.${RESET}"
    exit 1
fi

# Done
echo -e "\n${GREEN}🎉 MACFIX installation complete!${RESET}"
echo -e "${YELLOW}🔁 Please reboot to activate the drivers.${RESET}"
