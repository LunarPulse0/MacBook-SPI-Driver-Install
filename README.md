# 🍏 MACFIX – Linux Drivers for MacBook / MacBook Pro

**MACFIX** is a one-click solution to enable MacBook keyboard, trackpad, and ambient light sensor support under Linux.

Whether you're on Ubuntu, Arch, Fedora, or another distro — MACFIX uses DKMS and kernel modules to make your MacBook work the way it should.

---

## 📦 What’s Included

This repo includes:

- ✅ Keyboard driver (`applespi`)
- ✅ Trackpad + bridge drivers (`apple-ibridge`, `apple-ib-tb`)
- ✅ Ambient light sensor driver (`apple-ib-als`)
- ✅ DKMS configuration
- ✅ One-click install script (`macfix.sh`)
- ✅ Makefile for manual builds

---

## 🚀 Quick Install (Recommended)

1. **Make the script executable:**

   ```bash
   chmod +x macfix.sh
   ./macfix.sh
