# Other applications for Arch Linux

## 3D printing

### PrusaSlicer

I started off with Slic3r, which I found to be the best open-source slicer option.  Well, the best option in general, really.  It has advanced features, but also works just fine for basic stuff.  It can publish directly to my OctoPrint server running on Raspberry Pi too, so it's super convenient.  I first started using the "Prusa Edition" because it was less buggy and scaled better in Linux, but now the two have diverged even further, and it seems the best features and reliability are still with the now-named PrusaSlicer.

1. Install the `prusa-slicer` package.
    - Files related to this app are stored in ~/.PrusaSlicer

### OpenSCAD

Used for 3D modeling.  Scales and functions perfectly at least since the 2019-05 release!

### Arduino IDE

I know this isn't necessarily for 3D printing, but I use it for updating the firmware on my 3D printer.

Install `arduino` and `arduino-docs` packages.

To fix scaling:

1. Go to `File` → `Preferences`.
2. For `Interface scale` uncheck `Automatic` and enter your desired scale.
3. Click `OK`.

Menus and some dialogs still don't scale right.  I've read about a solution involving a font setting in `~/.gtkrc-2.0`, but I couldn't get it to work for me.

I prefer to keep my home directory more organized; to change the directory for Arduino files:

1. Go to `File` → `Preferences`.
2. Change `Sketchbook location`; for example: `/home/david/code/arduino`.
3. Click `OK`.
4. You may want to move the files from the original location, usually `~/Arduino`.

## Audio editing

### Audacity

The latest version uses GTK3 and the UI elements scale in size nicely.  However, there are still some issues with fonts in some places, but it is totally usable.

1. Install the `audacity` package.
2. If you're using dark theme, it will look messed up at first.  Go to `Edit` → `Preferences` → `Interface` and change `Theme` to `Dark`.

## Git GUI client

- GitAhead - seems pretty full-featured, but has a strange interface...
- SmartGit - so far, seems to be the most fully-featured; however, it is only free for personal use and not open source.
- Gitg - really simple and no push functionality, but otherwise nice.
- Git Cola - seems really customizable and may be nice if I can get used to it, but I can't seem to find out how to see a simple list of commits that shows tree structure.
- GitExtensions - Used to be cross-platform, but now is only for Windows.  The old version is still available for Linux.  It's ugly and has some scaling bugs, but sadly still works the best for me compared to the others.
    - Install `gitextensions` AUR package.
    - Some work is needed to get it to prompt for SSH key passwords.  This will set it up to work through KDE Wallet:
        1. Install `ksshaskpass` package, if it's not already installed.
        2. Set `SSH_ASKPASS` variable to `/usr/bin/ksshaskpass` by creating the file `~/.config/plasma-workspace/env/askpass.sh` with the content:
            ```
            #!/bin/sh
            export SSH_ASKPASS='/usr/bin/ksshaskpass'
            ```
    - TODO: Cover merge tool
    - Some other settings:
        - `Git Extensions` → `Git Extensions`
            - `Show current working directory changes as an artificial commit`: Checked
            - `Use FileSystemWatcher to check if index is changed`: Checked
            - `Close Process dialog when process succeeds`: Checked
        - `Git Extensions` → `Appearance`
            - `Code font`: `DejaVu Sans Mono, 10`

## Steam

1. Add `multilib` pacman repository.
2. 32-bit OpenGL drivers are also needed.  For AMD and Intel, install `lib32-mesa`, and for NVIDIA, install `lib32-nvidia-utils`.
3. The locale `en_US.UTF-8` is required and must be generated.  If you followed the instructions in this repository to install Arch Linux, you probably already have this locale unless you chose a different one.
4. Steam relies on Microsoft fonts; install `ttf-liberation` to get free substitutes.
5. Install `steam` package.