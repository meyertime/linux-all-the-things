# Arch Linux on Lenovo ideapad Flex 5 14" AMD (14ARE05)

As always, do at your own risk.  This documentation is provided in good faith, but with no warranty.  (See [LICENSE](../LICENSE).)

For now, I am using the [Lenovo 720S](arch-lenovo720s.md) doc for the most part.  Here I will document exceptions for the this model.

## Accessing UEFI firmware setup and boot menu

It is possible to use Windows to boot into UEFI firmware setup; however, this is not recommended, because Windows may not be fully shut down in that case.

On this Lenovo laptop, there are these better methods:

- Use `F2` key at power on to enter UEFI firmware setup.  I find the easiest way that doesn't involve bashing the key repeatedly is to simply press the power button while power is off, then immediately press and hold the `F2` key until the setup screen is displayed.
    - Note that this laptop has a feature called "one key battery", which is enabled by default, that displays battery information when the power is off and a key on the keyboard is pressed.  This interferes with my other method of entering setup which involves pressing the `F2` key before pressing the power button.  That is why I adjusted to pressing power first, then the `F2` key immediately after.  It is also possible to disable this feature in the UEFI firmware setup.
- Use `F12` at power on to enter UEFI boot menu.  Same strategy here as the `F2` key above.

Here are some other settings you may want to change while you're in UEFI firmware setup:

- `AMD SVM Technology` - Disable virtualization for security purposes if it's not needed
- `Flip to Boot` - I'm not exactly sure what this does, but I'm guessing it will turn on power when the device is flipped into tablet mode.  I've disabled this so that the power button must be used to power on.
- `Fool Proof Fn Ctrl` - Makes the `fn` key act like `ctrl` for keys that don't have a function associated with them.  I prefer users to know what keys they are pressing and disabled this.
- `Charge In Battery Mode` - This only affects when the devices is powered off or hibernating.  The only use for this is if you want to use your laptop battery as a portable battery pack for other devices.  Disable to avoid draining the battery.

Note that this model does not have the ACPI storage mode that needed to be disabled in other Lenovo models.  I am guessing this is because it is an AMD laptop and the ACPI storage mode was for an Intel controller that this model lacks.




## Notes

`iwctl` for connecting to wireless network?
1. iwctl
2. device list
3. station [device] scan
4. station [device] get-networks
5. station [device] connect [SSID]]
6. You will be prompted for the password
7. exit

Or if you know the device and SSID: `iwctl station [device] connect [SSID]`



To move partition, used GParted.  Couldn't get GParted ISO to work when written directly to USB stick.  Instead, using multiboot.

Ventoy!
Install `ventoy-bin` from AUR.
`sudo ventoy -i -r 1000 -g /dev/sdc` - Install ventoy on the USB drive using GPT and leaving 1GB for persistent storage.
This destroys all data on the drive and creates a boot partition and an exFAT partition to hold images.
I didn't reformat the ISO partition, but apparently you can.  I'd like to reformat to ext4.
To take advantage of the 1GB kept for persistent storage, you have to create a third partition there and format it.
At this point, it will only boot if Legacy boot mode is enabled in the UEFI firmware.



AMD graphics
Install xf86-video-amdgpu
For 3D acceleration: mesa, lib32-mesa, libva-mesa-driver, lib32-libva-mesa-driver, mesa-vdpau, lib32-mesa-vdpau



Hide grub menu
edit /etc/default/grub:
# First, shorter timeout
GRUB_TIMEOUT=1
# Then, hide menu during timeout
GRUB_TIMEOUT_STYLE=hidden
sudo grub-mkconfig -o /boot/grub/grub.cfg
Use Esc during boot to access menu



Swap file
set swappiness to 10
size recommendation without hibernation: if <2GB, 2x; if <8GB, 1x; otherwise 0.5x
dd if=/dev/zero of=/swapfile bs=1M count=512 status=progress   # 512 MiB
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
add line to /etc/fstab: /swapfile none swap defaults 0 0

enable/disable hibernation?


Optimize mirror list automatically
timer is now part of the reflector package
/etc/xdg/reflector/reflector.conf
--save /etc/pacman.d/mirrorlist
--protocol https
--age 12
--country US
--latest 30
--number 20
--sort rate


SSH remote administration
Edit /etc/ssh/sshd_config:
HostKey /etc/ssh/ssh_host_ed25519_key
AllowUsers david
PasswordAuthentication no
ChallengeResponseAuthentication yes   # Need to comment above where the default is no, or it causes problems
AuthenticationMethods publickey,keyboard-interactive:pam
PermitRootLogin no

Generate host key:
sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
(May not be necessary, as sshd seems to generate all the default ones)

Add public keys to ~/.ssh/authorized_keys for each authorized user

Start/enable sshd.service



Os-prober is now disabled by default

Pamac-aur now needs libpamac-aur first

Fix systemd-backlight failure
Added kernel parameter acpi_backlight=video or =native fixed failure, but there's still issues adjusting brightness

Fixed kvm disabled error by blacklisting kvm and kvm_amd kernel modules

Sftp access to meyer-server
Try it out:
sudo sshfs david@meyer-server:/ /net -o identityfile=/home/david/.ssh/id_ed25519_sftp_david -o allow_other -o default_permissions -o uid=1000 -o gid=1000
Add to fstab:
david@meyer-server:/ /media/meyer fuse.sshfs noauto,x-systemd.automount,_netdev,identityfile=/home/david/.ssh/id_ed25519_sftp_david,allow_other,default_permissions,uid=1000,gid=1000,reconnect,ServerAliveInterval=5,ServerAliveCountMax=3 0 0
Connect once as root to add known hosts




cloning a file system
check using `fsck -f /dev/mmcblk1p4`
shrink using `resize2fs -M -p /dev/mmcblk1p4`
make sure the destination file system is capable of supporting a file so large
copy the first so many bytes of the disk using `ddrescue -s <size in bytes> /dev/mmcblk1p4 /path/to/image/file /path/to/rescue.map`
or quicker:
    check the block size of the output device with `blockdev --getbsz /dev/sdb1`
    `dd if=/dev/mmcblk1p4 of=/path/to/image/file bs=4096 count=<size in bytes> iflag=count_bytes status=progress` 
check the image integrity using `fsck.ext4 -f /path/to/image/file`
important: expand the file system again, as it has no free space now.  the partition size has not changed, but the file system size has changed.  to expand it again: `resize2fs -p /dev/mmcblk1p4`
before restoring to the new machine, back up a few key files, like fstab
restore: dd if=/path/to/image/file of=/dev/mmcblk1p4 bs=4096 status=progress
expand file system to fill partition: `resize2fs -p /dev/mmcblk1p4`
after restoring, make some changes: fstab, hostname, hosts
actually, do all arch installation steps from the fstab point forward that don't involve installing packages
regenerate kernel images? `mkinitcpio -P` - ended up having to reinstall linux package




e2guardian
Copied *.conf from /etc/e2guardian and everything in /etc/e2guardian/lists
Create certificates:
- openssl genrsa 4096 >private_root.pem
- openssl req -new -x509 -days 3650 -key private_root.pem -out my_rootCA.crt
- openssl x509 -in my_rootCA.crt -outform DER -out my_rootCA.der
- openssl genrsa 4096 >private_cert.pem
- create /etc/e2guardian/generatedcerts/
for some reason, there's no e2guardian user or group...
- useradd -r -s /usr/bin/nologin e2guardian
need to do some permission things:
- remove group/other permissions to /etc/e2guardian/private/ and its contents
- change owner of generatedcerts dir to e2guardian
- create /var/log/e2guardian/ if it doesn't exist and change owner to e2guardian
- enable e2guardian service
install certificate in firefox and operating system
- through firefox settings window
- copy my_rootCA.crt to /etc/ca-certificates/trust-source/anchors/
- sudo trust extract-compat
configure proxy systemwide
- in /etc/environment, set http_proxy, https_proxy, ftp_proxy, and no_proxy, and upper-case versions
lock firefox settings
- copy settings from /usr/lib/firefox/mozilla.cfg
- need to add /usr/lib/firefox/defaults/pref/autoconfig.js
- but i think i ended up not doing this, going the firewall route instead
firewall
    `iptables -A OUTPUT -o lo -p tcp -j ACCEPT`
    `iptables -A OUTPUT -p tcp -m owner --uid-owner e2guardian -j ACCEPT`
    `iptables -A OUTPUT -p tcp -m owner --uid-owner david -j ACCEPT` - optional
    `iptables -A OUTPUT -p tcp --destination-port 21 -j REJECT`
    `iptables -A OUTPUT -p tcp --destination-port 80 -j REJECT`
    `iptables -A OUTPUT -p tcp --destination-port 443 -j REJECT`
    `iptables-save -f /etc/iptables/iptables.rules`
    `systemctl enable iptables --now`



From main list:
- Fix network/wifi
- KDE Plasma theme (each user)
- Set up package manager GUI and AUR
- Change screen off delay (each user)
- Mouse settings
- Customize KDE Plasma desktop session (each user)
- Swap file (fixed size)
- Optimize mirror list automatically
- Fix font issues
- Install common desktop applications
    - dolphin firefox kcalc kate libreoffice-still okular vlc gwenview
- User profile (each user)
- Time synchronization


todo:
X timekpr
    X time limit settings
    X auto-restart service
X e2guardian
X zoom
X plasma themes
- meyer-server backup
    access is there, just need services to perform the backups automatically
- firefox settings
X ssh remote administration
X printers
- fix brightness thingy