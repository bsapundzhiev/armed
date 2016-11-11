## ARMed - Minimal Linux for armhf SoC's 
=====================================

ARMed is Ubuntu based Linux distribution for allwinner SoC's

Set of build scripts for Linux cross compilation and
rootfs from http://ports.ubuntu.com/ armhf port 

### Tools:
------
````
sudo apt-get install build-essential ncurses-dev 
sudo apt-get install u-boot-tools lzop
````

### Cross tools:
------------
for x86 host machines:
  ```
  # sudo apt-get install qemu-user-static debootstrap binfmt-support
  ````
Build:

	```
	./build.sh tools
	./buuld.sh [platform]
	```

### Install:
--------
resotre:
  ```
  # sudo ddrescue -d -D --force armed-sunxi-a13.img /dev/sdX
  ```
save:
  ```
  # sudo dd if=/dev/sdd of=./armed-sunxi-a13.img bs=1M count=4096
  ```

### License:
--------
Some scripts are based on "minimal linux live" https://github.com/ivandavidov/minimal so GPLv3 license is applied.
See COPYING file for copying permission.
