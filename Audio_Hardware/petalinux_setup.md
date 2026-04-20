Instructions are based on lab 3, but not the same!

After flashing the FPGA, run these commands on Ubuntu 22.04 or 24.04 LTS:
- `./petalinux-v2025.1-05180714-installer.run --platform "microblaze"`
- Enter `~/Petalinux_SoftData/2025_1_microblaze` when asked where to install the SDK. 
- `source ~/Petalinux_SoftData/2025_1_microblaze/settings.sh`
- `petalinux-create project --template microblaze --name ~/Petalinux_HardData/Linux_ADC_2025_1_S`
- `cd ~/Petalinux_HardData/Linux_ADC_2025_1_S`

After creating the project for the first time or after changing the hardware, run these commands:
- `petalinux-config --get-hw-description /path/to/ADC_TOP_wrapper.xsa`
- `petalinux-config -c u-boot` and go into “Networking → Networking Stack” select “No networking support” 
- `petalinux-config -c rootfs` and go into "Filesystem Packages → devel → python3" activate python3 and python3-mmap. Also go to "Filesystem Packages → misc → packagegroup-core-ssh-dropbear" and disable all options.
- `petalinux-build`
- `petalinux-package --force prebuilt`
- `petalinux-boot jtag --prebuilt 3`

Usage tips:
- Open up a terminal over serial using PuTTY, picocom, or similar.
- Once the OS boots, enter "petalinux" for the username, and set any password.
- Type `vi` in the terminal to access a text editor (`vi` is the predecessor to `vim`, and has many of the same keybinds)
- When running python-mmap script, make sure to use `sudo python3` instead of just `python3`
