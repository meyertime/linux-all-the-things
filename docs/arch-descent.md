# Descent on Arch Linux

My preferred Descent port is dxx-rebirth.

## Installation

1. Install the AUR packages `d1x-rebirth` and `d2x-rebirth`.
    - At the time of this writing, the git versions are significantly newer and better and I recommend them: `d1x-rebirth-git` and `d2x-rebirth-git`.
    - I have also run into an issue where the `sdl` dependency cannot be found.  I worked around it by manually installing the latest `sdl` first.
    - I have also had it get stuck in the middle of installing.  Even after cancelling, it won’t install packages because it thinks there’s another package manager running.  In that case, remove the file `/var/lib/pacman/db.lck`.
2. Make a rule to disable compositing while Descent is open.  This improves video performance.
    1. Open `System Settings`.
    2. Navigate to `Workspace` → `Window Management` → `Window Rules`.
    3. Click `New...`
    4. Enter the description `Descent`.
    5. Select only `Normal Window`.
    6. Enter window title `Regular Expression` `^D[12]X-Rebirth`.
    7. Click `Appearance & Fixes`.
    8. Tick `Block compositing` and select `Force` and `Yes`.
    9. Click `OK`.
3. Load game content.  This is not documented in a very easy-to-find location, but on Linux, it will look for game content in `/usr/share/d1x-rebirth` or `~/.d1x-rebirth` (same pattern for `d2x`).  The package installs a couple addons under `/usr/share/d1x-rebirth`, but it appears from the code that it will not delete any files added there if you reinstall.  I would recommend making a backup copy of game data elsewhere just in case, however.
    1. Choose where you will save the game data.  I find it easier to use the home directory because it does not require root access to change files there.  However, if the computer has multiple users that want to play, then I would recommend putting the game data under `/usr/share`.
    2. Copy the game data.  Make sure to include all `.hog`, `.pig`, `.ham`, `.mvl`, `.s11`, and `.s22` files if any exist as well as the entire contents of the `missions` directory, if any.
    3. If using the home directory and you wish to use a different music addon than the default SC55 one, then delete the `.dxa` file from the directory under `/usr/share`, or move it somewhere else.  I like to keep a directory like `~/d1x-rebirth/addons` to keep all addons not being used.

## Setup ps3pie

Setup `ps3pie` if you wish to use the PS3 controller.

1. Install node.
    1. Install the `nvm` AUR package.
    2. `echo 'source /usr/share/nvm/init-nvm.sh' >> ~/.bashrc` to source nvm for bash.
    3. Start a new terminal session.
    4. `nvm install 10` to install node.js 10.
2. Install `python2`.  This is needed by the `ioctl` dependency.
    1. `sudo pacman -S python2`
3. Install ps3pie.
    1. `npm i -g https://github.com/meyertime/ps3pie.git`
4. Fix hidraw permissions.
    1. Follow the instructions at [https://github.com/meyertime/ps3pie]().
5. Fix uinput permissions.
    1. Follow the instructions at [https://github.com/meyertime/ps3pie]().

## Automate some things

You can trick the shell to run a script instead of the Descent executable which can automate some things when Descent starts and exits.  You do this by creating a file with the same name as the executable in `/usr/local/bin`.  For example, I use this to set screen brightness and sound volume to maximum, because the hotkeys that control these do not work while Descent is running.

Since I like to use the same options to launch Descent 1 and Descent 2, I structure it this way:

1. `dxx-rebirth` is a more generic script that does the start and exit steps and executes whatever command you pass to it in between.  It is called by the other scripts.
2. `d1x-rebirth` and `d2x-rebirth` simply run `dxx-rebirth` passing in the full path to the Descent executable as an argument.
3. I also have `d1x-rebirth-dev` and `d2x-rebirth-dev` which do the same thing except pass the path to a locally compiled executable for development purposes.

Create `dxx-rebirth`:

1. All scripts must start with `#!/bin/bash` as the first line and use `chmod +x dxx-rebirth` to add execute permission.
2. Set max screen brightness:
    ```
    BRIGHTNESS=`qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl brightness`
    BRIGHTNESS_MAX=`qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl brightnessMax`
    qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl setBrightnessSilent $BRIGHTNESS_MAX
    ```
3. Set max sound volume:
    ```
    VOLUME=`amixer sget Master | awk '/%/ {gsub(/[\[\]]/,""); print $4; exit}'`
    amixer -q sset Master 100%
    ```
4. Optionally, launch ps3pie:  (this script uses `nvm` to manage node.js versions)
    ```
    . "$HOME/.nvm/nvm.sh"
    nvm exec 10 ps3pie &
    sleep 2s
    ```
5. Execute the command passed as an argument:
    ```
    $1
    ```
6. Reset screen brightness
    ```
    qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl setBrightnessSilent $BRIGHTNESS
    ```
7. Reset sound volume
    ```
    amixer -q sset Master $VOLUME
    ```
8. Stop ps3pie if started:  (this should be simpler than it is...  this actually kills all processes that descended from the running shell script)
    ```
    list_descendants ()
    {
        local children=$(ps -o pid= --ppid "$1")
        
        for pid in $children
        do
            list_descendants "$pid"
        done
        
        echo "$children"
    }
    kill $(list_descendants $$)
    ```

Create `d1x-rebirth`:

1. All scripts must start with `#!/bin/bash` as the first line and use `chmod +x dxx-rebirth` to add execute permission.
2. Run Descent:
    ```
    dxx-rebirth /usr/bin/d1x-rebirth
    ```

Create `d2x-rebirth`:

1. All scripts must start with `#!/bin/bash` as the first line and use `chmod +x dxx-rebirth` to add execute permission.
2. Run Descent:
    ```
    dxx-rebirth /usr/bin/d2x-rebirth
    ```
