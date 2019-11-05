# Arch Linux ARM

## Installation

Followed the instructions here for the most part: https://archlinuxarm.org/platforms/armv6/raspberry-pi

Except:

- I used `f2fs` file system instead of `ext4`.
- When moving files to the boot partition, it will warn about not being able to preserve ownership.  That is expected, because FAT32 does not have any concept of owner.

## SSH access

Default user name is `alarm` password `alarm`.  Use `su` to get root access; default password is `root`.

## Reboot remotely

You can always unplug/replug, but that’s a little harsh.  Here's a command:

1. `shutdown -r 0` to reboot immediately.
2. `shutdown 0` to shut down immediately, such as before unplugging.

## Set up wifi (Raspberry Pi)

Wired is already configured to connect and use DHCP.  A special adapter is needed to connect it directly over USB.  Connect over wired for now and SSH.

1. Use `su` to get root access.
2. `wifi-menu` will walk you through setting up a new wifi connection.
    - Forgot to use `-o` option to obscure the password.  At least that’s the option I remember... could be wrong.
3. `systemctl enable netctl-auto@wlan0.service` assuming `wlan0` is the interface.
    - Some docs say to use `netctl enable wlan0-my-wifi-connection` using the name of the wifi connection set up earlier.  However, apparently that is insufficient to get wifi to connect automatically, and it interferes with the above `netctl-auto` service from working properly.  Using only the steps above should get wifi connecting automatically.
4. Reboot.  It should now connect to the wifi network automatically.

## Set host name and passwords

1. `hostnamectl set-hostname myhostname`
2. Add lines to `/etc/hosts`:
    ```
    127.0.0.1    localhost
    127.0.1.1    myhostname.home    myhostname
    ```
3. `passwd` as root to change root password.
4. `passwd alarm` as root, or `passwd` as alarm to change alarm password.

## System update

1. `pacman -Syu` as root.

## Set up AUR

1. Install `base-devel` and `git` packages.
2. At this point, you can install AUR packages the manual way, which you will have to do in order to install an AUR helper.  I would prefer `pacaur` since it’s written in bash/C, but it doesn’t install in Arch Linux ARM due to a missing dependency.  `yay` is the most popular now, but it uses Go which is a relatively heavy download.  If you have some other reason to install Go, then go with yay.  I decided to go with `pikaur` because it is written in python, and python is pretty common for AUR packages to require, and it’s less of a download than Go.
3. `git clone https://aur.archlinux.org/pikaur.git`
4. `cd pikaur`
5. `makepkg -si`
6. `pikaur -Syu` to do a full system upgrade including AUR packages.

## Swap?

## Useful packages

- vim
- sudo
    - `EDITOR=vim visudo` and uncomment the line that grants access to the wheel group.
        - Be careful that you uncomment the correct line.  Read the comments, because one line requires a password and one doesn’t.  I highly recommend requiring a password when using sudo.
        - I have no idea why the group is called “wheel”, but my research indicates that it is specifically for authorizing super user access.
    - `usermod -a -G wheel alarm` to add alarm to the wheel group.
