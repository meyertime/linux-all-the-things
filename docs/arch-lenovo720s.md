# Arch Linux on Lenovo 720S-15IKB

As always, do at your own risk.  This documentation is provided in good faith, but with no warranty.  (See [LICENSE](../LICENSE).)

For now, this documents everything.  In the future, I plan to separate the general parts and only the device-specific information will remain here.

## Overview

I'm a big picture person.  It helps me if I understand the basic concept before delving into the details.  Here I will describe the basic process of setting up this laptop with Arch Linux at a high level.

There are essentially three stages to the installation: preparing the computer, installing Arch Linux, then setting up and configuring the system.

A few things need to be done to prepare the laptop for Linux.  There are UEFI firmware settings that need to be changed, because the defaults will not work with Linux.  Also, some work needs to be done on the hard drive partitions to make a space for Linux.  Finally, the Arch Live image needs to be downloaded and put on a USB thumb drive to boot from.

The actual Arch Linux installation is not as complicated as some might think.  It involves booting into an Arch Live image, mounting and formatting partitions, installing the base packages, editing a few settings, and installing a bootloader.  However, it is made a bit more complicated due to the following:
- Arch installation requires an internet connection, and I'm assuming that you won't be connecting the laptop to a physical network cable.  Therefore, wifi needs to be set up.
- Arch Live uses a static mirror list that is most likely not optimized for your geographic location.  This can cause considerable slowness at best or completely prevent installation at worst.  The instructions will cover optimizing the mirror list.
- The console text is extremely small on a 4k screen.  The instructions cover installing and setting a larger console font.

The other reason why Arch is considered to have a complicated installation process is because Arch Linux itself consists of a very minimal Linux system with no graphical desktop environment or any other unnecessary packages.  Installing, for example, a desktop environment, is done manually.  That may sound difficult, but it's really just a matter of installing the right packages with `pacman`.  I will include a minimal desktop environment installation in the installation stage because it is easier to do from the Arch Live system before rebooting.

After Arch Linux is installed along with a desktop environment, the remaining post-installation steps are mostly a matter of preference, although there are some fixes to get wifi working, consistent scaling, consistent look-and-feel, and a working package management GUI.  I will cover everything I did to set up and configure my system, but you can pick and choose which items you wish to do.

## General

This section contains some general information that you may want to refer to later.  You may skip this section for now.

### Fully shut down Windows

Note that simply clicking "Shut Down" is not enough.  By default, when you "shut down" Windows, it does not really shut down completely.  Windows can get stuck in a boot loop if it is not shut down completely before the storage setting is changed in the UEFI firmware.  Furthermore, Windows may hijack the next boot and prevent another bootloader from being used, such as the one used for Linux, thus getting in the way of using dual boot.

A feature called "fast startup" is enabled by default.  This feature causes Windows to do a kind of limited hibernation where much of the operating system files are loaded into memory from an image instead of through normal boot.  The image seems to include storage drivers, which is why I think bad things happen if you change the storage mode of the controller for the boot drive.  When this is enabled, Windows also seems to take control of the next boot.

Also note that users have complained that fast startup gets re-enabled after certain Windows updates.  Therefore, make sure to check the setting anyway even if you have disabled it in the past.

1. Disable "fast startup".  It is not straight-forward to get to this setting:
    1. Open `Control Panel` (not `Settings`)
    2. Click `Power Options`
    3. Click `Change what the power buttons do`
    4. Click `Change settings that are currently unavailable`
    5. Untick `Turn on fast startup (recommended)`
    6. Click `Save changes`
2. Optionally disable hibernation.  Since fast startup uses hibernation to some extent, this may be another way to prevent fast startup.  This also frees up disk space, and chances are if you're planning to use Linux 99% of the time and Windows only in a blue moon, you will never need it.
    1. Check for `C:\hiberfil.sys`.  It is normally hidden unless you configure to show hidden files in explorer file options.  It normally takes up several gigs.
    2. Run Command Prompt as Administrator
    3. Type `powercfg /hibernate off`
    4. Confirm that `C:\hiberfil.sys` has disappeared.  If not, reboot.  If still there, delete it.
3. Shut down Windows.

### Accessing UEFI firmware setup and boot menu

It is possible to use Windows to boot into UEFI firmware setup; however, this is not recommended, because Windows may not be fully shut down in that case.

On this Lenovo laptop, there are these better methods:

- Use `F2` key at power on to enter UEFI firmware setup.  I find the easiest way that doesn't involve bashing the key repeatedly is to simply press and hold the key while power is off, then press the power button and continue to hold the F-key until the setup screen is displayed.  I don't think it matters what the hotkey setting is; you should not need to use the `Fn` key with it either way.
- Use `F12` at power on to enter UEFI boot menu.  Same strategy here as the `F2` key above.
- Use "Novo" button while power is off.  This will power on the laptop and display a special menu.  The button is located on the left side of the laptop and requires some kind of physical pin to press.  I find a tool used to open the SIM card drawer on a cell phone works well for this.  Cell phones often come with one of these tools in the box.  Alternatively, I've used a mechanical pencil with a bit of lead sticking out as well, but be careful not to break off any lead inside the hole.  If all you need is the firmware setup or boot menu, I recommend using the F-keys mentioned above since it doesn't require a tool.  In any case, the "Novo" button menu has these options:
    - `Normal Startup` - Pretty self-explanatory.  Boots the system normally in case you change your mind.
    - `BIOS Setup` - Boots into the UEFI firmware setup.  I believe this is a bit of a misnomer, since UEFI systems do not really have "BIOS" per-se.  I will always refer to this as "UEFI firmware setup", just know that it is the UEFI equivalent of a BIOS setup and that's what it refers to in this menu.
    - `Boot Menu` - Shows the boot menu allowing you to select which boot entry to use.  For example, use this to boot to a USB drive if that entry is not the first entry.
    - `System Recovery` - I assume this takes advantage of the Windows recovery partition to enable system recovery operations such as factory reset, but I have never used this option.

### Change environment variables in Linux

Obviously, to change temporarily within a terminal session:

- `VAR=value command` to change it just for that command.
- `export VAR=value` to change it for the terminal session.

To change it for a given user:

1. Edit `~/.profile` with the lines:
    ```
    #!/bin/bash
    export VAR=value
    export VAR2=value2
    ```
2. `chmod +x ~/.profile` if you just created the file in order to add execute permission to it.

To change it globally for the system:

1. Create a `.sh` file under `/etc/profile.d/` with the lines:
    ```
    #!/bin/bash
    export VAR=value
    export VAR2=value2
    ```
2. `chmod +x file` to add execute permission to the file.

## Preparing for installation

Some things required before starting the Arch installation process.

### Update the UEFI firmware

Assuming that your computer is still set up with just Windows and you have not changed the storage mode in the UEFI firmware, you should update the UEFI firmware before proceeding.  The reason I recommend this is because it is more difficult and riskier to do after Linux is installed, because they recommend resetting the UEFI firmware to factory defaults before updating.

If you have already installed Linux before or have previously changed the storage mode in the UEFI firmware for some other reason, you may follow the procedure for updating the UEFI firmware in the "Later" section.  Otherwise, follow these steps:

1. Boot into UEFI firmware setup.
2. Reset to factory defaults and save and exit.
3. Boot into Windows.
4. Download the firmware update utility from the Lenovo website.  I find it easiest to simply enter the serial number off the bottom of the laptop.  This ensures that you get the right software.
5. Run the update utility and follow the instructions.  It will involve rebooting.
6. Boot into Windows to make sure it will still boot properly.

### Configure UEFI firmware for Linux

Long story short, the storage mode needs to be changed to ACPI and secure boot disabled in order for Linux to work.  You can make these changes without losing the ability to boot into Windows; however, Windows has a way of hijacking the boot process which can cause problems.  Be careful to follow the procedure outlined below.

1. Fully shut down Windows.  Note that simply clicking "Shut Down" is not enough.  See the section "Fully shut down Windows".
3. Boot into UEFI firmware setup.
4. Set Intel storage to ACPI mode in order for Linux to be able to use the built-in hard drive.
    - The firmware will warn that all data will be lost, but that is not true.  Well, as long as the drive is still set up as it was from the factory, not in any RAID for example.  In any case, it does not trigger any kind of operation to erase data, but conceivably, it may be possible to suffer some data loss if special features of the Intel storage controller were being used previously.  It's a good idea to back up your data if you care about losing it.
    - Windows will get stuck in a boot loop if it was not shut down completely first!  Make sure you followed the directions in the section "Fully shut down Windows".
5. Disable secure boot, otherwise Linux will not be able to boot.  Some distros may support secure boot, but it would have to be configured and enabled later.
6. Disable discrete graphics card temporarily.  I've read that it can cause hangs before the proper drivers are installed, and if the hang happens at a bad time, it can corrupt the disk during OS installation.
7. While you're in there, you may want to change some other settings to your preference.
    - Disable hotkey mode.  By default, hotkeys (which are also F-keys) perform the hotkey function unless `Fn` is held down, in which case the F-key function is performed.  If you use F-keys more frequently than the hotkeys, such as when programming or using other keyboard-heavy interfaces, you may want to disable hotkey mode.  In that case, F-keys are performed by default, and `Fn` is held down for the hotkey functions.
8. Save and exit.
9. Boot into Windows to make sure it still boots properly.

### Rearrange disk partitions

From the factory, here are the partitions in the order they are laid out on disk:

1. EFI system partition, about 260 MB, FAT32.  This is convenient, because this partition can be used to be able to boot Linux as well.  Let's keep it as-is.  We will eventually mount this at `/boot` (or `/mnt/boot` from Arch Live during installation).
2. Reserved partition, about 16 MB.  This partition is required by some utilities in Windows.  It's tiny, so best to leave well enough alone.
3. Windows C: partition, remainder of space on disk, NTFS.  We will shrink and move this partition to make room for Linux.
4. LENOVO D: partition, about 5 GB if memory serves correctly, NTFS.  I noticed this partition after sending the laptop in to the Lenovo depot for repair.  They performed a factory reset because they claimed the hard drive was corrupted.  I'm not sure if they created this partition manually, or it got there as part of the factory reset, or if it was there from the beginning.  It stores about 2.5 GB of Lenovo drivers.
5. OEM partition, about 1 GB, NTFS.  Windows will not allow you to mount this partition to a drive.  I checked the GPT partition type, and it is "Windows Recovery Environment", also known as "Windows Preinstallation Environment".  Apparently, it is used by Windows to recover the system, probably for doing a factory reset.

Assuming that the disk partitions are laid out as it was from the factory, use the following step-by-step instructions.  All of this can be done in Disk Management in Windows unless otherwise noted.  If you don't already know how to work with disk partitions, then you probably shouldn't be doing any of this, and if you have already mucked with the partitions, then I'm sure you know what to do instead.

1. Work on OEM partition if desired.
    - This can be left as-is.  However, since factory reset can destroy the Linux partition, we may want to disable Windows' ability to do so.
        - I think this could be done by changing the partition type to something else--for example, a Windows basic data partition.
        - You could also remove the partition.  I think this would not cause any problems, unless you are trying to use some Windows recovery options; however, I have not tried this.
2. Do away with LENOVO D: drivers partition if it exists and if desired.  There's no sense in keeping the free space from this partition inaccessible, and I don't see a reason to keep these files in a separate partition.
    1. Copy the data from this partition into the Windows partition.  I copied them under `C:\LENOVO`.
    2. Delete the LENOVO D: partition
3. Shrink the Windows C: partition to make room for Linux.
    - 100 GB should be enough for Windows while allowing full OS updates.  After doing disk cleanup, uninstalling non-essential apps, disabling and deleting page files and hibernation and not necessarily caring about OS updates, 50 GB is sufficient.
    - Sometimes I have gotten an error the first time I tried to shrink the partition, but it worked the second time.
    - If it still doesn't work, it may be because the disk is too fragmented.  You may have to defragment the disk (not recommended for SSDs) or use some other tool to consolidate the data before shrinking.
4. Move the Windows C: partition to the right, next to the following partition (or end of disk if none).
    - This will allow the Linux partition to come before Windows on the disk.  That way, if you need more space on one partition or the other, you only have to move the smaller one.
    - I used GParted to move the Windows partition.  Windows booted fine after moving the partition; just make sure Windows was fully shut down last time (no fast startup, hibernate, etc.)
5. Optionally, create a Linux swap partition.  I personally opted for a swap file instead of a swap partition, because 16GB is plenty of RAM, and especially with an SSD, I plan to avoid swapping as much as possible, so it seems a waste to dedicate a whole partition to swap.  You may want a swap partition, however, if you plan to use a file system other than `ext4` which doesn't play well with swap files or if you have significantly less RAM or plan to do a lot of things with high memory usage at the same time.
6. Create a partition for Linux in the unused space.
    - I did this using Disk Management in Windows even though it doesn't use the right partition type for Linux.  It's easy enough to change the partition type later.  Disk Management also seems to keep the partition numbers in the order they are on disk, whereas when I did this using Linux once, new partitions always got the highest number.

### Configure hardware clock

Configure Windows to use UTC for the hardware clock.  This is the default for Arch Linux, whereas Windows uses local time by default.  Since they share the same hardware clock, they should be consistent.  Standardizing on UTC is better, because otherwise both operating systems may adjust the hardware clock for daylight savings time changes resulting in overcorrection.  So Windows is the one that needs to change.

1. Set registry value `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\RealTimeIsUniversal` to `1`.  The value type is `QWORD` for 64-bit Windows and `DWORD` for 32-bit Windows.
2. Restart Windows.
3. After I did this, the clock incorrectly showed UTC time instead of local time. To fix, go to adjust date/time and turn "set time automatically" off and on again.  This forces an immediate time update.

### Prepare Arch Live boot drive

1. Go to https://www.archlinux.org/download/
2. If you're a fan of BitTorrent, use that link to download.  Otherwise, click on one of the mirror links from the long list.
3. The specific file to download is named like `archlinux-2019.09.01-x86_64.iso`.  Download it.
4. There are ways to verify the integrity of the file to make sure it was not corrupted during download or tampered with by the mirror host.  However, I skipped that and won't cover how to do it here.
5. Write the image to a USB thumb drive.
    - From Windows, I recommend using "Rufus" to write the image if you do not already have such a program that you prefer.  Google it.
    - The image must be written to boot UEFI, not MBR; otherwise, the Linux bootloader (grub) will not be able to configure the UEFI boot properly.
    - The image takes up less than 1GB (at the time of this writing) so most likely any USB drive that isn't ancient would be big enough.

## Installation

Start by booting into Arch Live:

1. Shut down Windows.
2. Access the boot menu and select the USB drive.

### Connect to wireless network

After booting to Arch Live, we need to connect to wifi in order to get internet access.  Note that these instructions only apply to the Arch Live system.  The base Arch system that we will install does not include the needed packages for these instructions to work.  Furthermore, this will only connect to the network one time for this one boot; everything will be reset once you reboot.  So it's best to do all the installation steps in one go to avoid extra work.

1. `ip link` to list network interfaces. In my case, it was `wlp2s0`. If yours is different, substitute it instead of `wlp2s0` in the following steps.
2. `ip link set wlp2s0 up` may be required.
3. `wpa_passphrase my_essid my_passphrase >/etc/wpa_supplicant/my_essid.conf` to encrypt passphrase.
4. `wpa_supplicant -c /etc/wpa_supplicant/my_essid.conf -i wlp2s0` to test connection.
5. `wpa_supplicant -B -c /etc/wpa_supplicant/my_essid.conf -i wlp2s0` to connect in the background.
6. `dhclient wlp2s0` to get an IP address.
7. `ping archlinux.org` to test network.

### Optimize pacman mirror list

The mirror list included in the Arch Live ISO may not be optimized for your geographic location.  In my experience, the top mirror failed and the second one worked, but was slow.  Optimizing the list helps significantly.

1. Use `reflector` to update and automatically sort the mirror list.
2. `cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup` to make a backup copy of the mirror list.
3. `pacman -Sy reflector`
4. If this fails, edit `/etc/pacman.d/mirrorlist` manually.  Comment out any problematic mirrors from the top.
5. `reflector --country US --protocol https --age 12 --sort rate --save /etc/pacman.d/mirrorlist`, for example, to generate a new mirror list.  This example chooses mirrors in the United States using HTTPS (for security) which have been synchronized in the last 12 hours and sorts them by rate (speed).  Tweak to your needs if necessary.

### Set larger console font

My laptop has a 4k monitor, and the text is extremely small.  Let's download and use a bigger console font.  This will only apply until reboot.

1. `pacman -Sy terminus-font`
2. `setfont ter-d32n`

### File system

1. Use `fdisk` to manage partitions.
    - `fdisk /dev/nvme0n1`, for example, starts fdisk for the given drive.
    - It's easy enough to read the menus and proceed.
    - Some of the help screens are paged.  If so, the space bar prints the next page and the `Q` key exits the paged information.
    - If you opt for a Linux swap partition instead of a swap file, create that partition if you have not already.  Either way, change the partition type to Linux swap.  You can list known partition types in fdisk.
        - If you do choose a swap partition, configuring Arch to use it is not covered in this documentation.
    - Create the Linux partition in unused space if you have not already.  Either way, use the partition type for Linux root x86_64.  You can list known partition types in fdisk.
2. `mkfs.ext4 /dev/nvme0n1p3` to format Linux partition. This destroys all data on the partition!  Your device name may vary, so double-check this before running.  It should warn you if there's an existing file system.  If you just created a new partition, there should not be an existing file system.
    - This assumes an `ext4` file system.  This is the most common, stable, and reliable file system for Linux.  However, there are better choices for an SSD, but they have some gotchas:
        - First some details about `ext4`.  It is a more traditional journaling file system similar in principle to Windows `NTFS`.  This means that write operations are first written to a journal and then to the actual file.  That way, if the write operation is interrupted, data is not lost or corrupted, because write operations can be replayed or rolled back from the journal.  Such file systems take advantage of the journal to enable snapshot functionality as well.  However, this does not play as well with SSD, because writes are spread across the disk and not necessarily aligned perfectly with flash blocks.  However, modern SSD drives do have the ability to transparently spread writes across the disk for the sake of longevity, so it may not be as big of an issue anymore.  In any case, Lenovo chose the SSD installed in this laptop with the intention of running Windows which uses such a file system, so I am not so worried about using `ext4`.
        - `btrfs` is an advanced copy-on-write file system.  The structure of writes allows features like snapshots and so forth without the need for journaling.  It has been around for quite some time, but still is not considered fully reliable.  It does have great tooling support, however.  Partitions can be grown and shrunk live.  It is also the default file system for openSUSE.
        - `f2fs` is also a copy-on-write file system, but it is specifically designed for SSDs.  It is considered more stable and reliable; for example, it is used on several Android smartphones.  However, the tooling support is not as great.  For example, at the time of writing this, there is no way to shrink an `f2fs` partition.  The data would have to be backed up into a different file system, then restored to a new `f2fs` partition of a smaller size by copying files.
3. `mount /dev/nvme0n1p3 /mnt` to mount Linux partition.
4. `mkdir /mnt/boot` to make empty directory for mounting EFI boot partition.
5. `mount /dev/nvme0n1p1 /mnt/boot` to mount EFI boot partition.

### Actual Arch install

1. Bootstrap Arch system
    1. `pacstrap /mnt base linux linux-firmware base-devel` to install base packages on new system.
        - Since I originally wrote this, `base` was changed from a group to a package.  I presume this was to give more flexibility to choose a linux kernel and other packages.  The installation guide now recommends to install `linux` and `linux-firmware` in addition to `base`, and this is equivalent to installing `base` before.  It also mentions that the base install no longer includes an editor (presumably `vi`?) so you may also want to install `vi`, `vim`, or some other editor at some point.
        - You may not need `base-devel` if you don't plan on developing software; however, it is required in order to install packages from AUR, because such packages are built on your machine. You can always install later if needed. Just know that `base-devel` will not be installed automatically if needed; you may get some cryptic error message instead.
    2. `genfstab -U /mnt >>/mnt/etc/fstab`
        - Generates the file system table.  This makes the mounting of the root and boot partitions permanent.
    3. `arch-chroot /mnt`
        - This is a "change root" or `chroot` operation. This temporarily changes the root directory `/` to point to some other directory. In this case, it will point to the root of the partition we set up to be the root of the new Arch system, so from this point forward, commands will behave as if they were run on that system instead of the Arch Live system. Furthermore, files from Arch Live, including any packages or executables, will no longer be available. Somehow, the network is still available, though.
        - You can exit `chroot` any time by typing `exit` to get back to the Arch Live system.
        - The remaining installation instructions assume you are running under `chroot`.
    4. `pacman -S intel-ucode` to enable microcode updates.  (If you have an AMD CPU, use `amd-ucode` instead.)
        - Processor manufacturers release stability and security updates to the processor "microcode".  Usually these are installed through UEFI firmware updates; however, manufacturers may be slow to do so or may have abandoned older hardware models entirely.  In this case, it is useful to have the bootloader load the updated microcode during boot.  After installing this package, the `grub` bootloader (installed later) will automatically detect and make use of it when generating its configuration.
2. Set time zone and locale
    1. `ln -sf /usr/share/zoneinfo/US/Central /etc/localtime`
    2. `hwclock --systohc`
    3. Edit `/etc/locale.gen` and uncomment `en_US.UTF-8 UTF-8`
    4. `locale-gen`
    5. `echo LANG=en_US.UTF-8 >/etc/locale.conf`
3. Set host name
    1. `echo myhostname >/etc/hostname` substituting your desired hostname
    2. Edit `/etc/hosts` adding these lines, substituting your host name:
        ```
        127.0.0.1    localhost
        ::1          localhost
        127.0.1.1    myhostname.localdomain    myhostname
        ```
4. Install bootloader
    1. `pacman -S grub efibootmgr os-prober`
        - Grub seems to be the bootloader of choice.
        - `efibootmgr` is needed to make UEFI boot entries. An entry will be created for grub automatically in a later step.
        - `os-prober` will detect other operating systems installed on the computer and add entries to grub for them. Grub will be the default boot entry, and there will be an option to boot into Windows from there.
    2. `grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB`
        - This installs grub on the system. It will add files to the EFI boot partition and make an entry in the UEFI boot table.
        - Make sure `/boot` is mounted to the EFI boot partition before running this. This was done in an earlier step. If not sure, run `mount` to list all mount points; `/boot` should be mounted to the first partition. You can also `ls` the contents of `/boot` to make sure it looks like an EFI boot partition.
    3. `grub-mkconfig -o /boot/grub/grub.cfg`
        - This generates the configuration file that grub uses when it boots.  Generally, changes are not made directly to this file.  Instead, it is generated by combining `/etc/default/grub` with scripts from `/etc/grub.d/`.
        - This is a good command to remember, since it has to be done again any time those files are changed.
5. `pacman -Syu` to update all packages
    - Generally there are no updates, but for some reason this is recommended at this point in the official Arch instructions.
6. Configure users.
    1. `passwd` to set root password
        - If you're not familiar with Linux security yet, "root" is a special user (sometimes called "super user") that has access to everything.  Typically, you should not log in as root or run applications as root.  Initially setting up a system or fixing a broken system would be notable exceptions.  For example, you were automatically logged in as root when you booted into Arch Live.
    2. Set up sudo.  When you do need "root" access, sudo is a way to do that securely.  You can use it to run specific commands with "super user" permissions as long as the account you are logged in as has permission to do so.
        1. `pacman -S sudo`
            - If you installed `base-devel` earlier, then `sudo` is already installed.
        2. `EDITOR=vim visudo` and uncomment the line that grants access to the wheel group.
            - Optionally substitute `vim` for the editor of your choice, assuming it's installed.
            - Be careful that you uncomment the correct line.  Read the comments, because one line requires a password and one doesn't.  I highly recommend requiring a password when using sudo.
            - I have no idea why the group is called "wheel", but my research indicates that it is specifically for authorizing super user access.
    3. Create regular users.  You will want at least one for yourself so that you do not have to log in as root.
        1. `useradd -m -G wheel -s /bin/bash david` to create a user.
            - Omit `-G wheel` if you do not want the user to have super user permissions.
        2. `passwd david` to set the user's password.
        3. Repeat for additional users if desired.
7. Do not shut down or exit `chroot` yet, as setting up the graphical desktop components is easier if you continue as you are.

### Install desktop environment

At this point, if you rebooted, you should successfully boot into your new Arch system.  However, you would only get a bash command line interface, and just getting wifi working in order to install further packages would be a pain, if it's even possible.  (I didn't try that hard.)  Therefore, I recommend continuing on to install the remaining desktop components before rebooting.

In this section, we will install the minimum for getting KDE Plasma up and running such that we can boot into it and use a terminal emulator or other application to finish setting up the system.  

These instructions assume that you are either in `chroot` or booted directly into your Arch system and that you have internet access.  If you are stuck because you rebooted, you can boot back into Arch Live, follow the instructions above to connect wifi, mount your Linux root partition to `/mnt` and EFI boot partition to `/mnt/boot`, and `arch-chroot /mnt` to get back to where you need to be.

1. `pacman -S xorg` to install xorg window system.
2. `pacman -S sddm` to install SDDM display manager.  This is the display manager recommended by KDE for use with Plasma.  I also like how it can be configured right in KDE and provides a consistent look and feel.
3. `systemctl enable sddm.service` to enable SDDM at startup.  This is actually what causes the system to boot into a graphical login screen rather than a command line shell when it starts.
4. `pacman -S plasma` to install KDE Plasma.  Note that this is the package group rather than meta-package.  I prefer groups to meta-packages because individual components of groups can be uninstalled later without uninstalling the entire group.  Also, this actually only installs a stripped-down desktop environment with very few apps such as system settings; it does not even include a file manager, terminal emulator, text editor, or web browser.  There is an even more stripped down package called `plasma-desktop`; I'm not sure what the difference is, but I found `plasma` plenty lean enough.
5. Optionally install "kde-applications".  This group will install the whole KDE application suite.  It most likely includes many apps that you don't need or won't use.  So basically decide whether you would like to start with a full-featured desktop and trim out apps from there or start with a super bare-bones system and install only the applications you want.
    - `pacman -S kde-applications` to install the full KDE app suite.
6. If you don't install "kde-applications", install a terminal emulator such as "konsole".  Without this, you will have no way to configure the system or install software after you boot into the desktop.
    - `pacman -S konsole` installs Konsole.
7. Reboot and log in to KDE Plasma
    1. `exit` to exit chroot.
    2. `reboot` to reboot system.
    3. First run should launch SDDM, though it will look wonky compared to the KDE theme.
    4. Log in as the user you created.

## After install

The following steps can be done in any order.

### Install Linux LTS kernel

Sometimes the latest kernel may break things.  For example, I have had my touchpad randomly stop working.  It's useful to be able to boot to the LTS kernel in that case.

1. `sudo pacman -S linux-lts`
2. `sudo grub-mkconfig -o /etc/grub/grub.cfg`

You can now access the LTS kernel in the boot menu under advanced options.

Arch/GRUB currently has what some consider to be a bug where it treats `linux-lts` as if it were newer than `linux` and puts it higher in the boot menu, thus selecting it by default.  Most people who have both kernels installed intend `linux-lts` as a safe backup and want `linux` to be the default, however.  Here are a couple workarounds:

#### Change order of boot menu

Unfortunately, this is not straight-forward.  I did figure out a rather hacky way.  It involves overriding a function defined in `/usr/share/grub/grub-mkconfig_lib`.  To do this, I added a wrapper at `/usr/share/grub-custom/grub-mkconfig_lib` that imports the real library and overrides the one function, and a script in `/etc/grub.d/` that overwrites the original library with this wrapper.  It is designed so that updates to the grub packages should not break the fix.

1. Create the directory `/usr/share/grub-custom` and copy [grub-mkconfig_lib](../src/grub/grub-mkconfig_lib) to it.
    - This file is designed to be used in place of the real `grub-mkconfig_lib`.  It imports the real library and then overrides a defined in it.
    - It overrides `version_test_gt` which tests whether or not one version is greater than another.
    - The problem has to do with the fact that the versions come up as `linux` and `linux-lts` and do not include the actual kernel version numbers.  In that case, it sorts them alphabetically, in which case `linux` would come before `linux-lts`, or be considered "less than".  In reality, `linux` is always greater than `linux-lts` in terms of kernel version.  To correct this, I simply replace an ending of `linux` with `linux-zzz` which should make it greater than any other `linux-` kernel.
2. Copy [01_custom_lib](../src/grub/01_custom_lib) to `/etc/grub.d/`.
    - This file replaces the real `grub-mkconfig_lib` with the custom wrapper.  It first makes a copy of the real library named `grub-mkconfig_lib.orig` so that the wrapper can import the real library.  If the real library is replaced for any reason with one that is not the custom wrapper, such as by updating the grub package, it will update the `grub-mkconfig_lib.orig`.  It will also update `grub-mkconfig_lib` with a newer version of the custom wrapper if one is written to `/usr/share/grub-custom/grub-mkconfig_lib`.
    - This file must have a number less than 10 so that it is executed before `10_linux`, which is where the linux entries in the boot menu are generated.  I suppose, technically, it could be `10_custom_lib` because it would still come before `10_linux` alphabetically, but it's safer to choose a lower number.  Plus the in-between numbers are specifically for system installers or administrators as mentioned in the `README` in the same directory, so `01` seemed like a natural choice.
3. `sudo grub-mkconfig 2>/dev/null` to generate a new `grub.cfg` and print it to stdout.  Check the output to be sure it is right.  Omit the `2>/dev/null` part if you want to see stderr output as well.
4. `sudo grub-mkconfig -o /boot/grub/grub.cfg` to generate a new config and save it.

#### Change default entry and/or flatten

A simpler solution is to change the default boot entry.  The entries will still appear out of order, but at least the correct default will be used.

Whether or not you change the default, you may also want to flatten the boot menu.  If you do, the boot menu entries under the `Advanced` submenu will appear simply in the top menu instead.  There will be no main entry for Arch Linux in the top menu anymore.  This entry is apparently always equivalent to the first entry in the `Advanced` submenu.  There does not appear to be a way to change this, which is why changing the default without flattening the menu may not be desirable.  In that case, the main Arch Linux entry at the top is basically useless, and you would still have to press `Enter` twice to select the default instead of waiting for the timeout.  Finally, even if you do change the order of the boot menu, you may still prefer to flatten the menu, especially since there is probably plenty of room on the screen to do so.

1. Edit the file `/etc/default/grub`.
    1. Add a section at the end for custom values.  I like to do this, anyway, to keep them separate from the defaults.
    2. To flatten the boot menu, add `GRUB_DISABLE_SUBMENU=y`.
    3. To change the default menu entry, add `GRUB_DEFAULT='gnu-linux-advanced-01234567-89ab-cdef-0123-456789abcdef'`, for example.
        - To find the ID of the menu entry that you want to set as default, look in `/boot/grub/grub.cfg`.
2. `sudo grub-mkconfig 2>/dev/null` to generate a new `grub.cfg` and print it to stdout.  Check the output to be sure it is right.  Omit the `2>/dev/null` part if you want to see stderr output as well.
3. `sudo grub-mkconfig -o /boot/grub/grub.cfg` to generate a new config and save it.

### Fix network/wifi

If there is no network/wifi icon in the icon tray, it may be because NetworkManager is not started.

1. Open Konsole (or whichever terminal you installed earlier)
2. `sudo systemctl start NetworkManager.service`
3. If that worked, make it permanent by enabling the service on startup: `sudo systemctl enable NetworkManager.service`
4. Use the network/wifi icon to connect to your network.

### KDE Plasma theme

I prefer a dark theme, because `dark > light`.  The default SDDM theme also does not match KDE's default theme.  Follow these instructions for a consistent dark theme.

1. Set KDE Plasma theme
    1. Open `System Settings`
    2. Navigate to `Appearance` → `Look and Feel`
    3. Choose `Breeze Dark`
2. Set GNOME/GTK application style to match.  This applies to apps that use the GTK toolkit such as Firefox.
    1. Open `System Settings`
    2. Navigate to `Appearance` → `Application Style` → `GNOME/GTK Application Style`
    3. Change GTK2 theme to `Breeze-Dark`
    4. For GTK3 theme, use `Breeze-Dark` theme and tick the box `Prefer dark theme`.  I have found these settings to work the best.
    5. Under `Icon Themes` select `Breeze Dark` for `Icon theme` and `Fallback theme`.
    6. Click `Apply`.
3. Set cursor theme
    1. Open `System Settings`
    2. Navigate to `Appearance` → `Workspace Theme` → `Cursors`
    3. Select `Adwaita`
    4. Navigate to `Appearance` → `Application Style` → `GNOME/GTK Application Style`
    5. Under `Icon Themes` select `Cursor theme` `Adwaita` to match.
2. Set SDDM theme to match
    1. Open `System Settings`
    2. Navigate to `Workspace` → `Startup and Shutdown` → `Login Screen (SDDM)`
    3. Click `Breeze`
    4. Click `Apply`
    5. Click `Advanced` tab
    6. Click `Sync`
        - This will sync other settings besides the theme including NumLock and scaling.

### Fix scaling

My laptop has a 4k screen, so obviously scaling is necessary.  Scaling is a bit hit-or-miss when it comes to Linux, because of the many fragmented GUI toolkits.  However, my combination of Arch and KDE seemed to handle scaling well.  Still, there are some manual steps to get configure scaling and fix a few scaling issues.

1. Set KDE Plasma display scaling.
    1. Open `System Settings`
    2. Navigate to `Hardware` → `Display and Monitor` → `Displays`
    3. Click `Scale Display`
    4. Set the slider to 2.  (This equates to 200%.  On a 4k screen, that would make things the same size as a 1080p screen is normally.)
    5. Click `OK`
    6. Reboot to apply changes
2. Enable SDDM scaling.  This fixes scaling for the login screen.
    - This can be done automatically to match KDE Plasma scaling:
        1. Open `System Settings`
        2. Navigate to `Workspace` → `Startup and Shutdown` → `Login Screen (SDDM)`
        3. Click `Advanced` tab
        4. Click `Sync`
    - Or, to do it manually:
        1. Create the file `/etc/sddm.conf.d/dpi.conf` with the following content:
            ```
            [X11]
            ServerArguments=-dpi 192
            ```
            - 192 should be equivalent to 200%.
3. Fix taskbar scaling.
    1. Fix icon tray scaling.
        1. Set the environment variable `PLASMA_USE_QT_SCALING=1`.  See the heading on how to change environment variables.
        2. Reboot.
        3. If that doesn't work (which may happen after installing the not recommended `xf86-video-intel` driver), you can specify a bigger size specifically for the icons in the icon tray:
            1. Edit the file `~/.config/plasma-org.kde.plasma.desktop-appletsrc`.
            2. After every line that commences `extraItems=` add another line `iconSize=2`.
                - This actually ends up being a bit bigger than I would prefer, but unfortunately, fractional numbers are not permitted.
            3. Reboot.
    2. Adjust taskbar height if necessary.
        1. Click the configure icon at the right edge of the bar.
        2. Find the `Height` button.  Drag it with the mouse to adjust the height.
    3. This is more of a tweak than a fix:  You can configure the task manager to show only one row which allows you to keep it slightly taller without wrapping the buttons.  Instead, the text inside wraps, which is handy.
        1. Click the configure icon at the right edge of the bar.
        2. Hover over the task manager and click `Configure...` in the menu that appears.  This opens `Task Manager Settings`.
        3. Under `Appearance`, change `Maximum rows` to `1`.
        4. Click `OK`.
4. Fix mouse cursor scaling
    1. For the most part, the cursor scaling seems to work out of the box.  I did notice one instance where it was wrong: The cursor was tiny when hovering over title bars.  The following will make the scale consistent, but may prevent proper scaling of external monitors with different scales.
    2. Open `System Settings`
    3. Navigate to `Appearance` → `Workspace Theme` → `Cursors`
    4. Select a `Size` of `48, or whichever size you prefer instead of `Resolution dependent`.

### Set up package manager GUI and AUR

I'm thinking this is a tremendous oversight, but all known AUR helpers are installed via AUR...  This is a catch-22; before you can install any AUR packages with an AUR helper, you have to install an AUR helper manually.  Fortunately, AUR helpers appear to be able to bootstrap themselves and manage updates to their own AUR package once installed.

There are a number of options, but I am going with `pamac`.  It comes from Manjaro, and it is specifically designed for Arch, supporting pacman and AUR directly.  It has a nice tray icon for updates as well.

1. Install some prerequisites: `sudo pacman -S base-devel git`
2. Change to a temporary directory, such as `/tmp`.
3. `git clone https://aur.archlinux.org/pamac-aur.git`
4. `cd pamac-aur`
5. `makepkg -si`
6. Pamac is installed now.  Launch it and configure it to enable AUR.
    1. Click the menu icon and click `Preferences`
    2. Click to AUR tab.
    3. Tick `Enable AUR support`
    4. Recommend ticking the following boxes as well:
        - `Check for updates from AUR` - Otherwise, you will not see updates from AUR
        - `Check for development packages updates` - Sometimes AUR packages need to be rebuilt when dependencies are updated.
    5. While you're there, under the `General` tab I recommend ticking `Remove unrequired dependencies` as well.
7. Use pamac to install `pamac-tray-appindicator` from AUR.
    - Log out and back in to get the tray icon to appear.
8. Optionally, use pamac to remove `Discovery` which is the package management GUI that comes bundled with KDE Plasma.  Discovery cannot handle Arch packages without a backend, and the only backend that supports Arch packages is PackageKit, and PackageKit is not recommended because it allows package installation without root access, and the maintainer is deprecating it.  Although, I think you can manage Plasma-specific packages like themes and such with Discovery, so keep it if you like.

### Start with Numlock on

By default, the computer is started with Numlock off.

There are two ways to go about this.  First, you can configure KDE's Numlock setting and sync that th SDDM.  This is useful if you are syncing other settings to SDDM.

1. Configure KDE's Numlock setting
    1. Open `System Settings`
    2. Navigate to `Hardware` → `Input Devices` → `Keyboard`
    3. Under `NumLock on Plasma Startup`, tick `Turn on`
2. Sync SDDM settings
    1. Open `System Settings`
    2. Navigate to `Workspace` → `Startup and Shutdown` → `Login Screen (SDDM)`
    3. Click `Advanced` tab
    4. Click `Sync`

Or, you can do it the manual way.  SDDM starts before KDE Plasma, so it makes sense to configure that to activate Numlock while configuring KDE Plasma to leave the Numlock setting alone.

1. Configure SDDM to activate Numlock
    1. Create the file `/env/sddm.conf.d/numlock.conf` with the following content:
        ```
        [General]
        Numlock=on
        ```
2. Configure KDE Plasma to leave Numlock setting alone
    1. Open `System Settings`
    2. Navigate to `Hardware` → `Input Devices` → `Keyboard`
    3. Under `NumLock on Plasma Startup`, tick `Leave unchanged`

### Change screen off delay

KDE's default timeout for dimming and turning off the screen is really short, and it gets very annoying.  Here's how to fix it.

1. Change lock screen delay
    1. Open `System Settings`
    2. Navigate to `Workspace` → `Workspace Behavior` → `Screen Locking`
    3. Enter a more sensible lock screen delay, like 15 minutes.
    4. Click `Apply`
2. Change power settings for the display
    1. Open `System Settings`
    2. Navigate to `Hardware` → `Power Management` → `Energy Saving`
    3. Change settings for each power mode to your liking.  Here's what I use:
        - Screen brightness on Low Battery (default)
        - Dim screen after 9 minutes for all power modes (default is 2 minutes which is way too short)
        - Screen switch off after 10 minutes for all power modes
        - Suspend session after 15 minutes for power modes except AC Power
        - When laptop lid closed Sleep (default)
        - When power button pressed Sleep

### Boot terminal font size

First, we need to change it at the grub level.  Grub uses bitmap fonts, so we can't simply specify a different size.  We need to build a new font altogether.  Grub comes with a utility to do this.  DejaVu Sans Mono is a good choice as a source font; not only is it awesome, but it also has all the ASCII art characters for drawing borders and such.

1. `sudo pacman -S ttf-dejavu` to install DejaVu Sans Mono if you have not already.
2. `sudo grub-mkfont -s 36 -o /boot/grub/fonts/DejaVuSansMono.pf2 /usr/share/fonts/TTF/DejaVuSansMono.ttf` to generate a grub font.
3. Edit `/etc/default/grub` and add the following line:
    ```
    GRUB_FONT=/boot/grub/fonts/DejaVuSansMono.pf2
    ```
4. `grub-mkconfig -o /boot/grub/grub.cfg` to regenerate the grub config file.

Second, we need to change the Linux console font.  This applies after grub starts Arch.  The Linux console only supports PSF fonts.  Easier solution is to use the Terminus font:

1. `sudo pacman -S terminus-font`
2. Edit or create `/etc/vconsole.conf` and add the line:
    ```
    FONT=ter-d32n
    ```
3. Edit `/etc/mkinitcpio.conf`
    1. Locate the `HOOKS=` line; it may look like:
        ```
        HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
        ```
    2. Add `consolefont` near the end; for example:
        ```
        HOOKS=(base udev autodetect modconf block filesystems keyboard consolefont fsck)
        ```
4. `sudo mkinitcpio -P`
    - Note this will regenerate all images and may break the system.  There is a way to test it first, but I don't know how yet.

To get DejaVu Sans Mono in there, we need to convert it.

1. Download and set up some things...
    1. `pacman -S fontforge` to install needed package; or use the pamac GUI if you prefer.
    2. `pamac build bdf2psf` to install needed AUR package; or use the pamac GUI if you prefer.
    3. Download the fonts in source form (SFD) for FontForge from https://dejavu-fonts.github.io/Download.html
        - You may open the TrueType font installed at `/usr/share/fonts/TTF/DejaVuSansMono.ttf` instead, but it is better to use the source form.
2. Convert the font to BDF format using FontForge.
    1. Open `DejaVuSansMono.sfd` in FontForge.
    2. `Element` → `Bitmap Strikes Available...`
    3. Enter `32` for the `Pixel Sizes` (this is the largest size supported by `setfont`).
    4. Click `OK`
    5. `File` → `Generate Fonts...`
    6. Select `No Outline Font` in the left format drop-down box.
    7. Select `BDF` in the right format drop-down box.
    8. Make sure `32` is entered in the text box underneath `BDF`.
    9. Choose where you want to save it and the filename.  It will automatically append `-32` to the filename before the extension to what you enter here.
    10. Click `Generate`.
    11. The BDF resolution probably doesn't matter... just click `OK`.
3. Convert the font to PSF format.
    1. Go to a temporary directory such as `/tmp` in a terminal emulator.
    2. Copy the BDF file you created earlier to the current directory.
    3. `bdf2psf DejaVuSansMono-32.bdf /usr/share/bdf2psf/standard.equivalents /usr/share/bdf2psf/ascii.set 512 DejaVuSansMono-32.psf`
    4. `sudo cp DejaVuSansMono-32.psf /usr/share/kbd/consolefonts/`
4. Set `DejaVuSansMono-32` as the console font.

### Mouse settings

The settings in the KDE Plasma System Settings app have no effect.  You have to configure libinput manually.

1. Create the file `/etc/X11/xorg.conf.d/30-touchpad.conf` with the content:
    ```
    Section "InputClass"
            Identifier "touchpad"
            Driver "libinput"
            MatchIsTouchpad "on"
            ...
    EndSection
    ```
2. Add settings where the ellipsis is, for example:
    - Invert mouse scrolling direction (natural scrolling)
        ```
        Option "NaturalScrolling" "true"
        ```
    - Tap to click
        ```
        Option "Tapping" "on"
        ```

### Customize KDE Plasma desktop session

1. Open `System Settings`
2. Navigate to `Workspace` → `Startup and Shutdown` → `Desktop Session`
3. Under `On login`, tick `Start with an empty session` if you don't want applications restored after restart.
4. Under `General` untick `Confirm logout` to avoid the prompt when selecting logout, shut down, restart, etc.
5. Click `Apply`.

### Swap file

I opted for a swap file instead of a swap partition.  Swap partitions are fixed in length and are not trivial to resize.  On the other hand, swap files can be grown automatically as needed.  Not having any swap is also an option, but in that case, if the system runs out of RAM, it will crash entirely, which is a bit risky.  However, with 16GB of RAM, it is unlikely that you would hit that limit.  My compromise is to enable a swap file, but configure Linux to avoid swapping until absolutely necessary.  Another reason to avoid swapping is for the sake of the longevity of the SSD.  I will start with a relatively small swap file and allow it to grow if needed.

1. Note that if you are using a copy-on-write file system, there are some steps that need to be done first which are not covered here.
2. Set the system "swappiness" level.  It goes from 0 to 100, and lower values avoid swapping more.
    1. `sudo sysctl -w vm.swappiness=0` to set the level temporarily.
    2. To make the setting permanent, create the file `/etc/sysctl.d/99-swappiness.conf` with the content:
        ```
        vm.swappiness=0
        ```
3. Install package `systemd-swap`.
4. Edit `/etc/systemd/swap.conf`.
    1. Set `swapfc_enabled=1`.
    2. Set `swapfc_force_preallocated=1`.
        - This is necessary if you see `WARN: swapFC: ENOSPC` in the log, which happened in my case.
    3. Set other values as desired; for example, `swapfc_max_count` according to desired max size.  For example, 32 x 512M would equal 16GB.
5. `systemctl stop systemd-swap.service` to stop the service if it is already running.
6. `systemctl start systemd-swap.service` to start the service.
7. `systemctl enable systemd-swap.service` to enable the service.
8. Check settings before and after reboot.
    1. `cat /sys/fs/cgroup/memory/memory.swappiness` should show swappiness value of `0`.
    2. `swapon` should show swap files being used.

### Boot option for UEFI firmware setup

Now that I know the trick for using `F2` to enter UEFI firmware setup, this is not very important to me.

### Boot option for terminal mode

I have not figured out how to do this, but there is a pretty easy way to get into terminal mode:

1. `systemctl set-default multi-user.target`
2. `reboot`

To get back to graphical mode:

1. `systemctl set-default graphical.target`
2. `reboot`

### Battery fix

After doing some more research, the fix mentioned specific to this laptop called "Battery Conservation Mode" simply limits how high it will charge the battery to 50-60%.  I don't really see how that would improve battery longevity, and it's not what I want.

The other issue is how quickly the battery drains when suspended.  One way to improve this would be to enable suspend to disk, which would require a large static swap file, but the drain really should not be that much if suspend to RAM is working.  If battery drain issue is still noticed, then I need to find a way to check if suspend to RAM is working.

### Optimize mirror list automatically

1. Install AUR package `reflector-timer`.
    - `reflector` dependency will be automatically installed if needed.
2. Edit `/usr/share/reflector-timer/reflector.conf`, for example:
    ```
    AGE=12
    COUNTRY=US
    LATEST=30
    NUMBER=20
    SORT=rate
    ### remove an entry if you don't want it as available protocol
    #PROTOCOL1='-p http'
    PROTOCOL2='-p https'
    #PROTOCOL3='-p ftp'
    ```
3. `systemctl enable reflector.timer` to enable the timer.
4. Test it.
    - `systemctl start reflector.service` to run immediately.
    - `journalctl -u reflector.service` to check log.

### Intel graphics

There are a few drivers that can be used with the integrated Intel graphics adapter.  `xf86-video-intel` is designed specifically for Intel graphics, but it causes a few problems such as tearing and some scaling issues.  Arch, KDE, and a few other distros recommend against using it.  If this driver is not installed, it will fall back on `xf86-video-vesa` if it is installed.  However, that driver does not support hardware acceleration, so I also do not recommend it.  If that driver is not installed, then it will fall back to the "mode setting" driver which is built-in to the X window system.  This driver seems to perform the best and have the fewest bugs.  The following steps will make sure that you are using the mode setting driver.

1. `pacman -Ss xf86-video` will list all video driver packages and you will see `[Installed]` next to the ones that are installed, if any.
2. `sudo pacman -Rs xf86-video-intel` to remove the Intel driver if it is installed.
3. `sudo pacman -Rs xf86-video-vesa` to remove the VESA driver if it is installed.
4. `pacman -Ss xf86-video` to verify that these drivers are no longer installed.
5. Check all files in `/etc/X11/xorg.conf.d/` for any configuration that contains a section that looks like this:
    ```
    Section "Device"
            Identifier "Intel Graphics"
            Driver "intel"
    EndSection
    ```
6. Delete any such sections (or files if that's all they contain).  If you do not, it will try to use the Intel driver and it will hang forever at boot rendering your system unusable.  You may also want to check for any `Driver "vesa"` as well.
    - If you get stuck here, just boot into Arch Live using a USB thumb drive, mount your Linux root partition, and make the needed configuration changes.
7. Shut down.  For some reason, I have also had it hang at boot when rebooting after changing out the video driver.
8. Power on the computer.

### NVIDIA drivers

This laptop uses "Optimus" technology.  Essentially this means that the system has two graphics adapters: a low-power low-performance adapter built-in to the Intel CPU and the higher-power high-performance NVIDIA adapter.  The combination allows you to get the best of both worlds: high-performance graphics on demand for games and such and better battery life at other times.

There is a proprietary NVIDIA driver for Linux, but it is meant primarily for servers that use GPUs for calculations, so it does not cover the adapter switching.  For that, there is a FOSS solution called `bumblebee`.  I have used it before, but I now read that it has performance issues.  An alternative is `optimus-manager`.  It is not as user-friendly, but it lets you get the full performance out of the NVIDIA adapter.

There is a FOSS NVIDIA driver called nouveau, but at the time of this writing, its performance is much worse than the proprietary driver.  This may change, however, since NVIDIA has recently started to release hardware documentation to assist with open-source driver creation.

#### Optimus-manager

You can use `optimus-manager` to switch graphics modes using a command or an optional tray icon.  Doing so requires logging out and back in, however, to start a new desktop session.  It does not handle powering the NVIDIA chip off or on directly, however.  This can be handled by the priprietary NVIDIA driver on newer hardware, but not on my hardware.  In my case, I am using `bbswitch`, which is supported by `optimus-manager`.

1. Install `nvidia` package to get the latest proprietary NVIDIA driver for Linux.
2. Install `optimus-manager` AUR package.
4. Start and enable `optimus-manager.service`.
5. Set the startup mode to your liking:
    - `optimus-manager --set-startup intel`
    - `optimus-manager --set-startup nvidia`
    - `optimus-manager --set-startup hybrid`
6. Try using `optimus-manager` to switch graphics modes.
    - `optimus-manager --switch intel`
    - `optimus-manager --switch nvidia`
    - `optimus-manager --switch hybrid`
7. Install `bbswitch` package, or `bbswitch-dkms` if you are using a different kernel than `linux` or a downgraded version of it.  If using `bbswitch-dkms`, you will also need `linux-headers`.
8. Make a temporary `.conf` file somewhere:
    ```
    [optimus]
    switching=bbswitch
    pci_power_control=no
    pci_remove=no
    pci_reset=no
    ```
9. `optimus-manager --temp-config path/to/file.conf`
10. Test the config by switching a few times.  If you run into trouble, reboot the computer to load the normal config.
11. Save the working config to `/etc/optimus-manager/optimus-manager.conf`.
12. Install `optimus-manager-qt` AUR package to get the tray icon.
    - When installing, edit the build file and set `_plasma=true` if using KDE Plasma.
    1. Launch `Optimus Manager` app.  It will appear in the tray.
    2. Use the tray icon to launch settings.
    3. Tick `Launch at startup` and configure any other settings.
        - If `Launch at startup` does not take effect, it may be because the `~/.config/autostart` directory does not exist.  Create it.
    4. To make the icon permanently visible:
        1. Right-click the expand button in the system tray and click `Configure System Tray...`.
        2. Click `Entries`.
        3. For `Optimus Manager`, change `Visibility` to `Shown`.

##### Fix scaling in NVIDIA mode

Some KDE Plasma scaling is wrong after switching to NVIDIA mode using `optimus-manager`.  (See https://github.com/Askannz/optimus-manager/issues/154)  This is because the global scaling value sets all the screens in the `QT_SCREEN_SCALE_FACTORS` environment variable, but the screens have different names in NVIDIA mode.  For example, `eDP-1` becomes `eDP-1-1`.  Values need to be added for the NVIDIA screens.

1. Create the file `~/.config/plasma-workspace/env/nvidia-scale.sh` with execute permissions with this content:
    ```
    #!/bin/bash
    export QT_SCREEN_SCALE_FACTORS="${QT_SCREEN_SCALE_FACTORS}eDP-1-1=2;DP-1-1=2;HDMI-1-1=2;"
    ```
2. Log out and back in.

TODO: Slow shut down after installing `optimus-manager`

### Fix font issues

If you're reading this, you probably already know what I'm talking about.  For me, the fonts seemed fine at first until randomly, for some reason, the fonts in Firefox changed and it didn't seem to be picking the right font.

Part of the problem seems to be that the most popular fonts are proprietary Microsoft fonts (Arial, Times New Roman, and Courier New, for example).  Linux does not come with those actual fonts, for obvious reasons, but you can install substitutes.  Two such substitute packs include Liberation and DejaVu.  I personally installed both.

1. `sudo pacman -S ttf-liberation` - I think this is the font pack preferred by LibreOffice.
2. `sudo pacman -S ttf-dejavu` - This pack includes my monospace font of choice for programming: DejaVu Sans Mono`

While we're at this, maybe make DejaVuSansMono the default fixed width font:

1. Open `System Settings`
2. Navigate to `Appearance` → `Fonts` → `Fonts`
3. Change fixed width font to DejaVu Sans Mono 9pt.
4. Click `Apply`

### Install common desktop applications

If you installed the `kde-applications` package, you already have a ton of applications.  If not, you will want some common applications such as a file manager, web browser, calculator, etc.  At this point, you can use the pamac GUI to search and install the apps, so I won't show the pacman commands.

- File manager
    - Dolphin is the default for KDE, and it's pretty nice.
        - How to switch to double-click for opening files and folders:
            1. Open `System Settings`
            2. Navigate to `Workspace` → `Workspace Behavior` → `General Behavior`
            3. Tick `Double-click to open files and folders`
        - Show hidden files and folders:
            1. Click the menu button in Dolphin
            2. Click `Adjust View Properties...`
            3. Tick `Show hidden files`
            4. Click `OK`
        - Adjust icon size
            1. The slider at the bottom of the Dolphin window and about the middle actually controls the icon size.  Slide it all the way to the left for a nice compact layout.
- Archive manager
    - Ark
- Web browser
    - Firefox is the most popular open source option.  Support the open web!
- Calculator
    - Qalculate!
    - SpeedCrunch
- Remote Desktop Client
    - Remmina
        - For RDP support, install `freerdp` package or `remmina-plugin-rdesktop` AUR package.
            - At the time of this writing, it appears that rdesktop is no longer being maintained, whereas freerdp is.
        - To fix scaling for RDP:
            1. Click the menu icon in the title bar of the main Remmina window and click `Preferences`.
            2. Go to the RDP tab.
            3. Set device scale factor to `100%`.
                - I have experimented with this setting, and it does not appear to make any difference.  However, setting it to something is required to enable the other scaling field.
            4. Set desktop scale factor to match your desktop environment's scale factor or some other number if desired.  For example, if your desired scale factor is `200%`, enter `200`.
            5. Close the preferences window.
- Text editor
    - Visual Studio Code
        - Yeah, it's more for programming than just text editing, but it makes a good text editor too.
        - There is a known issue with the `code` package where elevating permissions to save files with root access does not work.  The workaround is to use the AUR package `visual-studio-code-bin` instead.  See https://github.com/Microsoft/vscode/issues/70403
    - Kate
        - KDE's text editor.  Not stellar, but works fine as a complement to a more developer-focused editor like Visual Studio Code.
        - Apply dark colors to the document itself too:
            1. Go to `Settings` → `Configure Kate...`.
            2. Go to `Editor Component` → `Fonts & Colors`.
            3. In the drop-down `Default schema for kate`, select `Breeze Dark`.
            4. Click `Apply` and `OK`.
- Office suite
    - LibreOffice
        - Install `libreoffice-still` for stable or `libreoffice-fresh` for latest.
        - Scaling worked for me out of the box now for `libreoffice-still`.
        - The icons did not show up properly for dark theme in my case.
            1. Open any LibreOffice app.
            2. Go to `Tools` → `Options`.
            3. Go to `LibreOffice` → `View`.
            4. Under `Icon style` select `Breeze (dark)`.
            5. Click `OK`.
- Document viewer
    - Okular
        - Views PDFs.  Not as full-featured as Adobe Reader, but decent for simply viewing docs.  It's a KDE app, so integrates well visually.
    - Boomaga
        - This app is specifically designed for printing documents.  Similar to Adobe, it can print multiple pages per sheet and booklets.
        - It can be set up as a virtual printer in order to integrate with other applications.  To do so, use the CUPS administration pages to add a printer and choose the detected local Boomaga printer.
        - You can also launch the app directly and open supported documents for printing, including PDF.
    - Adobe Reader
        - There is an AUR package `acroread` for installing Adobe Reader.  It worked for me at one time, but no longer.  It crashes immediately when starting.  I guess it's a really old version, because Adobe dropped Linux support some time ago.  I do not recommend using it.
- Video player
    - VLC
- Music player
    - Amarok
        - Requires a Phonon backend:
            - `phonon-qt5-vlc` - Since I already have VLC installed, it makes more sense to use this one.  Plus it is recommended by Phonon.
            - `phonon-qt5-gstreamer` - Preferred by some Linux distros in order to avoid patented codecs.
    - Pithos
        - Simple Pandora client that works nicely.
        - When I first tried to run it, I got an error about not having a secret service such as `gnome-keyring`.  All you need to do is install `gnome-keyring`.  This is because KWallet, which comes with KDE Plasma, does not support the newer standardized secret service protocol.  Pithos uses this, presumably, to store your Pandora password securely.
- Image viewer
    - Gwenview
- Image editor
    - GIMP
- Screen Capture - Linux does not necessarily have a built-in way to take screenshots.  The `PrintScreen` key is just a shortcut that launches the default screenshot application, so you may have to install one.
    - Spectacle
        - This is KDE's screenshot app and works fine.
        - I had some trouble getting the "Rectangular Region" function to work.  It may be related to having a multiple monitor setup.  In any case, when I press "Take New Screenshot", Spectacle disappears and nothing happens.  I was able to get around it by introducing a delay.  Since I don't really want a delay, I put `0.1 seconds`.
        - In addition to "Copy to Clipboard", you can also use the "Export" feature to open it with an image editor.

### Fingerprint reader

At the time of this writing, there is no known way to get this particular fingerprint reader to work.  It is possible, but a Linux driver does not exist yet.  The manufacturer is not interested in creating a Linux driver.  The protocol would have to be reverse-engineered.

### User profile

It's super easy:

1. Click the application launcher icon in the lower-left corner of the screen.
2. Click the box where your user image would be displayed.
3. Edit your name and picture, etc.

### UEFI boot entry cleanup

Sometimes I have ended up with junk boot entries.  For example, from a previous Linux installation or other operating system that is no longer on the computer.  Here's how to list and delete them:

1. The package for managing UEFI boot entries `efibootmgr` should already be installed if following the instructions here.  It would have been used by grub to add its boot entry during installation.  If not, install it.
2. `efibootmgr` to list boot entries.
3. `sudo efibootmgr -b 0003 -B` to delete boot entry `0003`, for example.

### Customize home directory structure

In general, Linux uses short snake-case names for directories and files.  (In other words, all lower-case sometimes with dashes separating words.  In some cases, underscores are used instead of dashes, but dashes seem to be much more common.)  I think one reason why this is the case is because Linux file systems are typically fully case-sensitive by default, and Linux users are typically heavy on terminal use.  As a result, if upper- and lower-case letters are used in file or directory names, you would have to remember and enter the correct casing in the terminal.  It's just easier to use all lower-case.

Windows, on the other hand, uses mixed case sensitivity; when opening a file, it is not case-sensitive, but when saving a file, the casing is preserved.  I never really thought much about this until I discovered that Linux is fully case-sensitive.  I guess it is possible to configure Linux to behave similarly to Windows in this respect, but I would rather just get used to the way Linux is typically configured.

The Linux desktop, however, differs somewhat from the rest of the typical Linux convention.  The default layout for the home directory includes title-cased directories for documents, music, pictures, etc.  These are not consistent with the rest of the file system, including many hidden files that exist within the home directory.  Yes, it does look neat and tidy if all you ever look at are files in your home directory, and you may be happy with that if you rarely use the terminal within your home directory.  However, I struggled for a time deciding whether to use snake-case or some other casing in Linux.  I was used to using some upper-case letters and spaces in Windows.  On the other hand, it kind of bothered me that this part of the file system was not consistent.  I eventually decided I should make the switch to snake-case and thus fully embrace the pattern most prevalent in Linux file systems.  As a side benefit, I don't have to worry about having to use quotes since there are no spaces.

Fortunately, the home directory structure can be customized easily.

1. Install the `xdg-user-dirs` package.
2. `xdg-user-dirs-update` will create all the well-known directories in your home directory if they do not already exist.  It will also create the `~/.config/user-dirs.dirs` file with the default values.
3. Edit `~/.config/user-dirs.dirs` file.  Change the directories according to your preference.
4. For each directory changed, rename the actual directories in your home folder.
    - The change to `Desktop` seems to take effect immediately, and the new desktop directory is created.  So in that case, you may have to move all the files into the new directory and delete the old one rather than rename it.
5. Run `xdg-user-dirs-update`.  If you did everything correctly, it should have no output and no effect.
6. Optionally, install `xdg-user-dirs-gtk` and run `xdg-user-dirs-gtk-update`.  This does something to integrate the user directory settings into GNOME and GTK+ applications.
7. Applications may need to be restarted before they will use the new directories, so it may be a good idea to reboot.
8. Fix Dolphin.  If you're using Dolphin, it seems to keep its own list of directories to show on the left sidebar.  You can right-click to edit each entry.  For example, the `Desktop` will need to be changed there if you changed that directory.
9. Most apps should respect the XDG standard and use the new directories, but some may require manual steps.
10. If all else fails...
    - Create symbolic links for each default directory (e.g. `Downloads`) that points to the new actual directory (e.g. `downloads`).  This way, even if apps try to use the default directories, files will still end up in the right place.
    - Use a `.hidden` file to hide the symbolic links.  (I have not actually tried this yet.)

### Set up multilib repository

This is needed for wine.

1. Edit `/etc/pacman.conf`.
2. Uncomment the `[multilib]` section and save.
3. Upgrade the repository listings with `sudo pacman -Syu`.

### Wine

Windows compatibility layer is handy for running some Windows apps without the heavy weight of a full virtual machine.

1. Make sure `multilib` repository is configured (see section).
2. Install the `wine` package.
3. Install `wine-mono` and `wine_gecko` as well.  Without these, wine will show pop-ups prompting to install .NET and Internet Explorer compatibility components.  It's better to use the distro-specific packages instead.

#### Stop wine from taking over as default application

Arch Linux wiki has a good write-up for this on: https://wiki.archlinux.org/index.php/Wine

See the headings "Unregister existing Wine file associations" and "Prevent new Wine file associations".

### File systems

- exFAT
    1. Install `exfat-utils`.
- FAT32
    1. Install `dosfstools`.
- f2fs
    1. Install `f2fs-tools`.
- NTFS
    1. Install `ntfs-3g`.

### Screen brightness

The lowest brightness setting when using the hotkeys is actually off...  This is not useful.  At the same time, it does not get very low in brightness before shutting off.  I was not able to find any settings to change this, but I did figure out a way to override the default behavior.

By default, it seems like there is more precision in the brightness at the higher brightness settings.  I personally think you need more precision at lower brightness settings and less at higher.  I also fixed this.

1. Write two bash scripts--one to turn down the brightness and the other to turn it up.
    - In this repository, [brightness-down.sh](../src/brightness-down.sh) and [brightness-up.sh](../src/brightness-up.sh) simply execute [brightness.sh](../src/brightness.sh) with a different parameter.
    - At first, I tried equal size steps, but that did not give good results.  It is now a hybrid approach which adds or subtracts 10% each time, but uses a minimum step size of 1/200 at the lower levels.  This gave higher precision at lower levels and a nice exponential progression at higher levels.
    - The scripts I wrote use `qdbus` which requires that `qt5-tools` packages be installed.
2. Open `System Settings`.
3. Navigate to `Workspace` → `Shortcuts` → `Custom Shortcuts`.
4. `Edit` → `New` → `Global Shortcut` → `Command/URL`.
5. Give it a name.
6. In the `Trigger` tab, click the `Shortcut` button and then press the button you want to use for the shortcut.
    -  In order to map the screen brightness hotkeys, since I have hotkey mode disabled, I had to press `Fn` and the screen brightness key at almost the exact same time.  Otherwise, just pressing `Fn` was enough for it to detect a different shortcut.
    - It will prompt you to reassign since the key is already used for screen brightness changes under power management.  Reassign it.
7. In the `Action` tab, type the path to your script.  (As always, make sure the script has a shebang line and execute permissions.)
8. Click `Apply` and try it out.
9. Repeat for the other screen brightness key.

### SSH

Surprisingly, Arch Linux does not come with an SSH client.  Install `openssh`.

To generate a new key:

- Best: `ssh-keygen -t ed25519`
- Fallback: `ssh-keygen -b 4096` (RSA)

Different keys for different hosts:

- Edit `~/.ssh/config`:
    ```
    Host SERVER1
        IdentitiesOnly yes
        IdentityFile ~/.ssh/id_rsa_SERVER1

    Host SERVER2
        IdentitiesOnly yes
        IdentityFile ~/.ssh/id_ed25519_SERVER2
    ```

To add a known host:

- Easiest way is probably `ssh user@host.com`.  If you choose `yes`, it will save the known host.  Also doubles as a way to check that the connection will work.

### Rename disk partitions

Sometimes in Dolphin file manager, I need to go to the root of the file system.  By default, this shows up as `Basic data partition` under `Devices` or some other generic name which is not very clear.  I would rather it say something like `Root`.  How do we change it?

Well, it's actually using the partition name here, which is sometimes set to `Basic data partition`.  You can change it with `fdisk`.  As always, when working with disk partitions, be very careful, because you can completely wreck your system and lose data.

1. `sudo fdisk /dev/nvme0n1`, or whatever device the partition you want to rename is on.
    1. Inside `fdisk`, use the `x` command to enter the expert menu.
    2. `p` to print the partition table.  In expert mode, it will show additional information including the name of each partition.  It's a bit hard to read unless the terminal window is really wide, however.  In any case, find out which partition number you want to rename.
    3. `n` to rename a partition.
    4. Enter the number of the partition you wish to rename.
    5. Enter the new name; for example, `Root`.
    6. `p` again to verify the changes are correct.
    7. `r` to return to the main menu.
    8. `w` to write the partition table to disk and quit.
2. Restart Dolphin or whichever file manager you use to see the changes.

### Set editor globally

Many linux terminal tools attempt to launch a text editor.  If one is not set globally, the default for that tool may not be installed or may not be your preferred editor.

1. Set the `EDITOR` environment variable.
    - For example: `EDITOR=vim`

### Sudo sugar

Sometimes you forget to type `sudo` when you need to, or maybe you just want a more polite way to ask for superuser permission.  If so, add this to your `~/.bashrc`:

```
function please()
{
    if [ $# -gt 0 ]; then
        sudo "$@"
    else
        local cmd=$(history -p \!\!)
        history -s please $cmd
        eval sudo $cmd
    fi
}
```

Start a new terminal for the change to take effect.  Now, if you forget to type `sudo` you can just type `please` to execute the previous command with `sudo`.  Or, you can also type `please xyz` instead of `sudo xyz`.

### Mount Windows partitions

Dolphin and other file managers have the ability to mount drives on demand using a background service, and this includes Windows NTFS partitions.  However, you may not want to mount these partitions, especially the `C:` OS partition, in read/write mode.

I was not able to find a way to prevent read/write mounting on certain partitions; however, you can achieve basically the same effect by auto-mounting the partition in read-only mode at startup.  I'm not sure if security-wise this prevents write access to regular users, but it would at least take some work and won't happen by accident.

It also may be useful to mount these partitions to permanent locations in the file system for easy shell access.

Basically, all you have to do is add them to `/etc/fstab` and reboot.

1. Make sure the `ntfs-3g` package is installed to enable full NTFS support.
2. Make a backup copy of `/etc/fstab` and have an Arch Linux Live USB stick handy in case you need it for recovery.
3. Choose the mount points you will use.
    - It is typical for major partitions to be mounted to directories directly under root; `/mnt` is for mounting temporarily.
    - I chose `/winc` and `/wind` for the Windows `C:` and `D:` partitions, respectively.
    - Create empty directories for these mount points.
4. Use `blkid` to find out the UUIDs of the partitions you wish to mount.
5. Add entries to `/etc/fstab`.  For example:
    ```
    UUID=0123456789ABCDEF  /winc  ntfs-3g  defaults,ro,nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000,windows_names  0  0
    UUID=FEDCBA9876543210  /wind  ntfs-3g  rw,nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000,windows_names  0  2
    ```
    - In this example, `/winc` is mounted read-only (see the `ro` option) and `/wind/` is mounted read/write (see the `rw` option).
    - Also, the last parameter is the priority for file system checking at startup.  According to the docs, the primary root Linux file system should be `1` and all other partitions `2`, while `0` disables file system checking.  So in this example, file system checking is disabled for `/winc` so as not to touch it, whereas it is enabled for `/wind` which is mounted also for writing.  You may wish to adjust these to your liking.
    - As far as the mounting options in this example, other than `ro` and `rw`, I copied them from somewhere online, and they work well for me.
6. Reboot and check that the partitions are mounted properly.

### Time synchronization

Time synchronization is not configured or enabled by default in Arch Linux.

Arch Linux comes with `systemd` which comes with `systemd-timesyncd` which is a simple NTP client daemon that will sync your clock.  However, it's a little _too_ simple for my taste.  For instance, my laptop's clock seems to have a lot of drift, as it gets more and more inaccurate as time goes on.  This built-in daemon will simply poll frequently enough to correct the drift, but if you are offline, it will drift until you are online again.  I also don't like the idea of polling too frequently, especially since it writes the time to a file every time it polls leading to frequent disk writes.  If you use a more sophisticated NTP client, it can measure and correct drift and keep the clock pretty accurate without polling a ton.

Meet `chrony`.  Here's how to set it up:

1. Install the `chrony` package.
2. Edit `/etc/chorny.conf`.
    1. Configure your NTP servers.  For example, to use pool.ntp.org:
        ```
        server 0.pool.ntp.org offline
        server 1.pool.ntp.org offline
        server 2.pool.ntp.org offline
        ```
        Note the `offline` part.  This puts `chrony` in offline mode when it starts since your machine probably won't have network access at that time.  You can change it to `iburst` otherwise.
    2. In my case, my real-time clock (RTC) is really slow.  While Chrony can get and keep the clock accurate while it's running, my time would get way off after turning off the computer.  Here are some settings that help keep the system time and real-time clock accurate even across reboots:
        ```
        driftfile /var/lib/chrony/drift    # Save drift information so that Chrony is aware of it across reboots
        rtcfile /var/lib/chrony/rtc        # Save more information about RTC accuracy when Chrony exits
        rtconutc                           # Tell Chrony that the RTC is in UTC
        rtcautotrim 30                     # Tell Chrony to update the RTC with the correct time whenever it gets out-of-sync more than 30 seconds
        ```
3. `systemctl enable chronyd --now`
4. Notify `chrony` when there are network state changes by integrating with `NetworkManager`.
    1. Install the `networkmanager-dispatcher-chrony` AUR package.

## Later

### Updating UEFI firmware

This can be tricky after Linux is installed.  I personally do not want to take the risk of trying to run the Lenovo firmware update utility in Linux, because it is designed for Windows, interacts with the hardware at a low level, and if something goes wrong, it has the potential to brick the laptop.  This is one of the main reasons I chose to keep the Windows partition around and the option to boot into Windows.

It is also recommended to reset the firmware to factory defaults before updating it.  However, the default settings will not allow Linux to boot, particularly due to the Intel storage mode and secure boot settings.  Further, Windows can get into a boot loop if it is not shut down completely before the storage setting is changed.  That boot loop will eventually attempt to diagnose and fix the startup process which involves reverting the UEFI boot entries (and possibly all UEFI settings?) to previous versions, and this potentially deletes the Linux boot entry.

I ran into those issues the one time I updated the firmware, so I do not know for sure how to avoid them, but I imagine the workflow would go like this:

1. Fully shut down Windows (see that section).
2. For good measure, boot into Linux to make sure Windows is fully shut down, then shut down the computer.
3. Boot into UEFI firmware setup.
    1. Write down all your current settings on paper.
    2. Reset to factory defaults (optional).
        - Since originally writing this, I did another UEFI firmware update and tried doing this without resetting to factory defaults.  It worked; however, the BIOS update utility did reset everything after the update.  There is a point where you can enter UEFI setup and set everything back before booting again, however.  I lost my GRUB boot entry in the process, but I don't know if that was a result of doing this trick or if that's what would have happened anyway.  In any case, it's fairly easy to restore the GRUB boot entry.
    3. Save and exit.
4. Boot into Windows.
    1. If done correctly, it should boot normally despite the change in Intel storage mode.
    2. Download the firmware update utility from the Lenovo website.  I find it easiest to simply enter the serial number off the bottom of the laptop.  This ensures that you get the right software.
        - Alternatively, if you have Lenovo Vantage installed, you can just run that.
    3. Run the update utility and follow the instructions.
        1. At some point, it will automatically reboot.
        2. After rebooting, you will see a command line utility flashing the firmware.
        3. After flashing, it will automatically reboot again.  This is the point where you can hold F2 to enter the UEFI setup utility before booting with the cleared settings.
5. Boot into UEFI firmware setup.
    1. Change Intel storage mode back to ACPI.
    2. Disable secure boot.
    3. Change any other settings to match what you wrote down before.
    4. Save and exit.
6. Boot into Windows to make sure it will boot correctly with the changed storage mode.
    1. Shut down Windows.
7. Boot into UEFI firmware setup.
    1. Check boot entries and order.
    2. Change any other settings to your preference.
    3. Save and exit.
8. Boot into Linux.

#### Restore GRUB UEFI boot entry

For one reason or another, you may lose the GRUB UEFI boot entry, in which case, the computer will boot directly to Windows, and GRUB will not appear in the UEFI setup boot section.  Here's how to restore it:

1. Insert your Arch Linux Live boot USB drive.
2. Hold F12 when booting the computer to enter the boot menu and select the USB drive to boot from.
3. Mount and change root into your Linux system:
    1. `mount /dev/nvme0n1p3 /mnt` to mount Linux partition.
        - Double-check that this is the right partition on your system.  For example, `ls /mnt` to see if the contents are what you expect.
    2. `mount /dev/nvme0n1p1 /mnt/boot` to mount EFI boot partition.
        - The `boot` directory _should_ already exist on your system.  Double-check that this is the right partition for your system.  For example, `ls /mnt/boot` to see if the contents look like an EFI boot partition.
    3. `arch-chroot /mnt`
4. `grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB`
    - This should be the same command you used when originally installing GRUB.
    - Since GRUB is already installed, it should skip the main installation and just create the EFI boot entry.

### Downgrading packages

I am not going to cover downgrading in general very thoroughly at this time.  The main reason I needed to do this was to downgrade the Linux kernel because version 5.4 broke my touchpad.  Note that this was the default `linux` kernel which is pretty bleeding-edge, not `linux-lts`.  However, `linux-lts` broke Bluetooth.  I wish there was something in between, but oh well.

#### Manually using the pacman cache

1. Go to the pacman cache directory: `/var/cache/pacman/pkg/`
2. Identify the package or packages you wish to downgrade.
    - `ls -ltr` will list them from oldest to newest.  It's convenient for figuring out which versions were used when it was working.
    - `ls linux* -ltr`, for example, to search specific package names.
    - For downgrading the Linux kernel, the Arch wiki recommends `linux`, `linux-headers`, and "any kernel modules".
3. `sudo pacman -U package-old_version.pkg.tar.xz`

#### The easy way

1. Install the `downgrade` AUR package.
2. `downgrade linux`, for example, to downgrade the `linux` package.
    1. It will list available versions from the Arch Linux Archive (remote) and the pacman cache (local).
    2. Select the version to downgrade to.
    3. It will automatically elevate to root when needed.

#### Prevent upgrades

1. To prevent the packages from being accidentally updated before the issue with the latest version is resolved, add them to the `IgnorePkg` section of `/etc/pacman.conf`.
    1. Locate the line that begins with `IgnorePkg=` which may be commented out.
    2. Change it to reflect your desired ignore list, uncommenting if necessary.  Multiple packages are separated by spaces.  Glob patterns may also be used.
