# IDrive Backup on Linux

Here is how to set up IDrive on Arch Linux.  It's probably still useful if you are using a different distro.

IDrive does not offer a Linux package.  However, they do have a set of Perl scripts that can be used to set up backups from Linux machines.  For some reason, they want you to contact support to get a link to the scripts.  At the time of writing, this is the link:

- https://www.idrivedownloads.com/downloads/linux/download-for-linux/IDriveScripts/IDriveForLinux.zip

## Installation

1. Download the script and unzip it.
    - The included `readme.txt` mentions that it "needs to be extracted into a particular folder", but does not suggest any particular directory.  The scripts seem to be written to detect where they are installed and use that directory, so apparently you can install it wherever you want.  I would suggest `/usr/local/bin`.
2. As mentioned in the `readme.txt`, you need to add execute permissions, because it's a `.zip` archive which does not support Unix file permissions.
    - `sudo chmod a+x *.pl` from the `scripts` directory.
3. On my system, I got the error `Your hostname is empty.` from some commands.  This was because the `hostname` command was not on the path.  Here's how to get it on the path:
    - `sudo ln -s /usr/lib/gettext/hostname /usr/local/bin/hostname`
4. The automated backups require some form of `cron` to be installed.  Arch Linux base does not include it, because systemd timers can be used instead.  I used `cronie`:
    1. `sudo pacman -S cronie`
    2. `sudo systemctl enable cronie --now`
5. The scripts are written in Perl, so make sure you have that installed.  My system already did.

## Security

I'm a little concerned about the security of these scripts...  The bad news is that the cron job for automated backup jobs runs as root.  The good news is that the user for each configured profile is impersonated when running the jobs.  I recommend creating a system user for IDrive:

1. `sudo useradd -r -m -s /bin/bash idrive`
2. `sudo -u idrive -s` to impersonate the `idrive` user.
3. Run the scripts as this user when configuring things.

There's another problem.  The scripts configure the permissions for configuration files to include write access for everyone.  If an attacker compromised any user on your system, they could potentially modify these files to cause bad behavior.  Some of these appear to be encrypted, but looking at the source code, it appears to be a rudimentary obfuscation that could be easily defeated.  The good news is that the scripts themselves should have the default permissions for your system, though I did not test what it does when it automatically updates the scripts.  So in that sense, it may be somewhat safe in that an attacker could only get the IDrive cron job to do what it's programmed to do.  At a minimum, I recommend taking a few precautions:

- `chmod o-w /etc/idrivecrontab.json`
    - This appears to be the file that stores the backup jobs that should run.  Removing others write access means you won't be able to configure your backup jobs, so wait until you're done configuring them.  You'll have to add access back in order to change the schedule.
- `chmod o-w /usr/local/bin/IDriveForLinux/idriveIt/user_profiles`
    - Inside this directory is a subdirectory for each configured user.  Once you've configured your user profiles, removing others write access means no new profiles may be created.  For example, an attacker could not create a profile for `root` in order to cause the IDrive cron job to modify files that `idrive` does not have write access to.
- `chmod o-w /usr/local/bin/IDriveForLinux/idriveIt/idevstil*`
    - These are executable files used by the IDrive scripts.  It's best if they cannot be written to without root access.

## Configuration

Read the `readme.txt`.  You should be able to figure it out from there, so I won't bother reiterating it here.