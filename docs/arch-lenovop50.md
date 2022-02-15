# Arch Linux on Lenovo P50

As always, do at your own risk.  This documentation is provided in good faith, but with no warranty.  (See [LICENSE](../LICENSE).)

For now, I am using the [Lenovo 720S](arch-lenovo720s.md) doc for the most part.  Here I will document exceptions for the P50.

## Accessing UEFI firmware setup and boot menu

It is possible to use Windows to boot into UEFI firmware setup; however, this is not recommended, because Windows may not be fully shut down in that case.

On this Lenovo laptop, there are these better methods:

- Press `Enter` when prompted "to interrupt normal boot".  You will be presented with a menu of options.  You may press `Enter` again to stop the timeout and give yourself more time to review the options.  You may access UEFI firmware setup with `F1` or the boot menu with `F12`.
- Use `F1` key at power on to enter UEFI firmware setup.  I find the easiest way that doesn't involve bashing the key repeatedly is to simply press and hold the key while power is off, then press the power button and continue to hold the F-key until the setup screen is displayed.
    - Note that once setup is entered, the held-down `F1` key will cause a help dialog to open.  Simply exit out of it.
- Use `F12` at power on to enter UEFI boot menu.  Same strategy here as the `F2` key above.

## Fix painfully slow GRUB menu

I have researched this issue and found many other cases, but no definitive fixes.  On this particular laptop, however, changing the graphics mode in GRUB to a lower resolution does fix the issue.

Here's a bit more background on this.  By default, GRUB appears to use whatever the current graphics mode is when control is passed to GRUB from the UEFI firmware.  When "Quick" boot is enabled in the UEFI firmware, which is the default, the graphics mode is set to 4k resolution (3840x2180), the native resolution of the monitor.  If the boot mode is set to "Diagnostic Splash" instead, then the graphics mode will be 640x480.  So one potential fix is to change the boot mode.  However, the graphics mode will remain at this low resolution until some point after the Linux kernel is loaded.  I would recommend deciding on a boot setting based on whether you want to see the diagnostic information at each boot or not and then configure GRUB to fix the slow menu issue.

GRUB has a setting that controls the graphics mode used for GRUB.  After Linux is loaded, however, the kernel will set the graphics mode according to its settings.  The default for Arch Linux is to keep the same graphics mode from GRUB until X sets it.  This can lead to some weirdness during the boot process.  For example, if you have set a large console font to make up for the 4k resolution, then you will see extremely large text for a moment until X increases the resolution.  In my opinion, the best solution would be to tell the Linux kernel to set the resolution right away.

1. Optionally, find out the available graphics modes.  Press `c` in the GRUB boot menu to enter the GRUB command line, and then type `videoinfo`.  Or, you can trust that they are the same as mine:
    ```
    0x000 1024 x  768 x 32
    0x001  640 x  480 x 32
    0x002  800 x  600 x 32
    0x003 3840 x 2160 x 32
    ```
2. Configure GRUB.
    1. Edit `/etc/default/grub`.
        1. Add `GRUB_GFXMODE=640x480x32,auto`.
            - Graphics modes follow the format `WIDTHxHEIGHTxDEPTH`.  You may specify more than one separated by a comma, in which case, if one fails, the next one will be tried.  Finally, `auto` is a special value that auto-selects a graphics mode.  It is recommended to include `auto` as the last value for safety.
        2. Add `GRUB_GFXPAYLOAD_LINUX=3840x2160x32,auto`.
            - This value tells the Linux kernel how to handle the graphics mode right away when it loads.  The special value `keep`, which is set by default for GRUB/Arch, causes the current graphics mode to be kept.  `text` will cause text mode to be used, which is a special graphics mode supported by some PCs.  Or, a specific graphics mode can be specified the same as `GRUB_GFXMODE`.
    2. Optionally, set a font for GRUB.  At the lower resolutions, the default font for GRUB looks just fine.  However, you may want the GRUB font to match your Linux console font.  Note that you will want a smaller size than the one used in the Linux console, since it will be displayed at a much lower resolution.  Here's how to set the smallest terminus font:
        1. `sudo pacman -S terminus-font`
        2. `sudo grub-mkfont -o /boot/grub/fonts/ter-x12n.pf2 /usr/share/fonts/misc/ter-x12n.pcf.gz`
        3. Edit `/etc/default/grub` and add the line `GRUB_FONT=/boot/grub/fonts/ter-x12n.pf2`.
    3. Optionally, make a backup copy of `/boot/grub/grub.cfg` in case there is a problem booting.  Also, it's good to have an Arch Live USB stick handy in order to be able to restore settings.
    4. `grub-mkconfig -o /boot/grub/grub.cfg`
    5. Reboot to test.

## Dual hard drives

On my particular P50, I have two hard drives.  One is a fast but relatively smaller solid-state drive (500GB SSD) and the other is a larger but slower spinning-disk hard drive (2TB HDD).  The laptop came with the SSD, and I later added the HDD when I needed more space.  This hybrid setup at least used to be rather common, though lately large SSDs have become within reach.

In any case, how do we handle splitting data between the drives in Linux?

Linux file systems are significantly different than Windows.  Windows is based on DOS (Disk Operating System).  As the name implies, it's disk-oriented.  All absolute paths begin with a drive letter, such as `C:` or `D:`, to indicate which disk the data is stored on.

Linux is based on Unix which has what's called a "unified" file system.  All absolute paths begin at the root `/`.  The file system also contains things other than files.  For example, hardware devices, processes, etc. are accessible through the file system.  Hard drives are devices that have a path in the file system.  They are accessed by mounting them to a location on the file system.  The root `/` is mounted from a drive partition.  Other partitions may be mounted to other locations.

In Windows, you typically store data on other drives by specifically saving it to the other drive letter.  As a user, you keep track of which drive you store what files in.  Some popular Unix features have made their way to Windows over the years, so it is possible to use a directory junction or symbolic link to cause a directory from one drive to map to a location on another drive.  However, this would be unnatural in Windows, since there would be some paths, for example, that begin with `C:\` that are actually stored on `D:\`.

That same solution, however, would be natural in Linux.  The underlying storage drive is not necessarily obvious from a Linux path.  For example, one thing that is very common is to mount another partition to the `/home` directory so that it stores all user files separate from system files.

However, I'm looking for something a bit more granular.  For example, I want to keep source code repositories on the SSD for speed, but my music collection on the HDD.  Both of these would fall under my home directory.  At the same time, I don't want a spaghetti mess of links between the drives that would be difficult to manage.

So here is my plan:  The HDD will have the same directory structure as the root file system on the SSD.  All symbolic links from the root file system on the SSD to the HDD will have the same path as their target on the HDD.  Thus, to see what files are stored on the HDD, I only need to check what's on the HDD, as the paths match.

So let's get started.

### Create and permanently mount the spin partition

I am going with `spin` or `Spinning Disk` for the name of this file system.

I am trying to do this the Linux way.  I was tempted to use directories under `/mnt`, but according to the Linux Information Project, `/mnt` is for mounting storage devices temporarily, whereas major file systems on other partitions are typically mounted right under the root directory.  Therefore, I am going with `/spin`.

1. Create the partition on the HDD and format it with an `ext4` file system.
2. Create the directory for mounting the HDD: `/spin`
3. Optionally, change the partition name of the `spin` partition.  As always, be careful when editing partitions to avoid data loss.
    1. `sudo fdisk /dev/sdb1` or whatever the device path of the hard drive is.
        - `x` enters the expert menu.
        - `p` lists the partitions.
        - `n` renames a partition.
        - `r` returns to normal menu.
        - `w` saves the partition table and exits.
4. Create a backup copy of `/etc/fstab`.
5. Use `blkid` to find out the UUID of the `spin` partition.
6. Edit `/etc/fstab` and add a line:
    ```
    UUID=01234567-89ab-cdef-0123-4567890abcdef  /spin  ext4  rw,relatime  0  2
    ```
7. Reboot and check that it is mounted properly.
    - The new `ext4` partition should contain a `lost+found` directory which should appear under the mount point `/spin`.
    - You can also run `mount` to list all mount points.

TODO: Set up and link directories

## Video

My video needs on the P50 are quite different than the 720S.  I am not concerned with video performance in the sense of 3D rendering for video games.  I use the P50 for work, so screen real estate is the name of the game.  I use it with 2 external 4k monitors: one connected to the rear thunderbolt port and one connected to the mini DisplayPort on the right side.  I also use the laptop monitor, also 4k, at the same time.

Here's what I know so far:

- Using the same `optimus-manager` solution in conjunction with the proprietary NVIDIA driver, `bbswitch`, and a UEFI firmware setting of `Hybrid` seems to work OK.  KDE is able to detect the external monitors and configure them.
    - However, the external ports are not available unless `nvidia` mode is selected.
    - In this configuration, the available outputs in `intel` mode are:
        - `eDP-1` - Internal laptop monitor
        - `DP-1-1` - Unknown, presumably one of: HDMI, mini-DP, Thunderbolt; however, it never shows as connected.  Most likely these ports are connected to the discrete NVIDIA chip and reverse PRIME is required to use them in `intel` mode.
        - `DP-1-2` - Unkonwn, ditto
        - `DP-1-3` - Unkonwn, ditto
    - In this configuration, the available outputs in `nvidia` mode are:
        - `eDP-1-1` - Internal laptop monitor
        - `DP-0` - Unknown
        - `DP-1` - Unknown
        - `DP-2` - Unknown
        - `DP-3` - Mini DisplayPort
        - `DP-4` - Thunderbolt port
        - `DP-4.*` - When connected to a Thunderbolt dock with multiple video ports, they may be enumerated this way
        - `DP-5` - Downstream Thunderbolt port
- I have also tried using the `Discrete Only` setting in the UEFI firmware as suggested in the Arch wiki with the proprietary NVIDIA driver.
    - A slightly different set of outputs results:
        - `DP-0` - Unknown
        - `DP-1` - Unknown
        - `DP-2` - Unknown
        - `DP-3` - Mini DisplayPort
        - `DP-4` - Internal laptop monitor
        - `DP-5` - Thunderbolt port
        - `DP-6` - Unknown
    - The internal laptop monitor does not advertise any modes other than its native 4k resolution.  At the same time, the computer boots at a lower resolution for some reason.  The kernel also no longer changes the resolution back to 4k during boot, but when X starts, it is able to.

### Using a Thunderbolt dock

It is possible to get dual 4k @ 60Hz through a Thunderbolt dock.  I use the Lenovo Thunderbolt 3 Dock Gen 2 (40AN0135US).  (I would like to acknowledge previous work on this subject that I found helpful [here](https://bbs.archlinux.org/viewtopic.php?id=255082) and [here](http://juho.tykkala.fi/Lenovo-Thunderbolt-3-dock-Linux).)

This was my first time using true Thunderbolt, and it was not super straight-forward.  Fortunately, most of what you need seems to be built into the regular Arch Linux kernel now, but you will need a user-space tool called `bolt`.

1. Make sure the `bolt` package is installed.
2. Connect power to the dock.
3. Plug the dock into the laptop's Thunderbolt port.  Make sure the other end is plugged into the Thunderbolt port on the dock that is meant for connecting to the laptop.  It has an icon of a laptop next to it in addition to the lightning bolt icon.
4. In a terminal, type `boltctl`.  It will list known and connected Thunderbolt devices.  Find the Lenovo dock and copy the UUID.
5. Type `boltctl enroll <uuid>` where `<uuid>` is the UUID value you copied earlier.  This will authorize the device _and_ save it to the database of authorized devices.  It is necessary for the dock to be fully functional.
6. Now you can plug everything into the dock if you haven't already.

There is a trick to getting two 4k @ 60Hz.  With both monitors plugged into the dock's DisplayPort ports, I could not achieve this.  I could only get one at 60Hz and one at 30Hz.  However, by plugging the second monitor into the downstream Thunderbolt port on the dock using a Thunderbolt to DisplayPort adapter, I was able to get both at 60Hz.  Apparently, that is how this dock is set up to handle the laptop's built in outputs.  One DisplayPort output on the laptop controls the ports on the dock, while the second output from the laptop is accessed through the downstream Thunderbolt port.  Perhaps a newer laptop can handle dual 4k @ 60Hz through the one output, but not my P50.

## Auto-disable wifi when network cable plugged in

Drop [99-wlan](../src/etc/NetworkManager/dispatcher.d/99-wlan) into `/etc/NetworkManager/dispatcher.d/` and make sure it has execute permission.

## Virtual audio devices

JACK is really powerful, but I need something simple and easy to use and configure.  ALSA has a module called `snd-aloop` which does the trick.

1. Create the file `/etc/modules-load.d/aloop.conf` with the content `snd-aloop`.
    - This causes the `snd-aloop` kernel module to automatically load at startup.
2. Create the file `/etc/modprobe.d/aloop.conf` with the content `options snd-aloop enable=1,1`.
    - This configures `snd-aloop` to have 2 virtual loopback devices.
3. Reboot for these settings to take effect.
