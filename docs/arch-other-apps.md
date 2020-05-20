# Other applications for Arch Linux

## 3D printing

### PrusaSlicer

I started off with Slic3r, which I found to be the best open-source slicer option.  Well, the best option in general, really.  It has advanced features, but also works just fine for basic stuff.  It can publish directly to my OctoPrint server running on Raspberry Pi too, so it's super convenient.  I first started using the "Prusa Edition" because it was less buggy and scaled better in Linux, but now the two have diverged even further, and it seems the best features and reliability are still with the now-named PrusaSlicer.

1. Install the `prusa-slicer` package.
    - Files related to this app are stored in ~/.PrusaSlicer

### OpenSCAD

Used for 3D modeling.  Scales and functions perfectly at least since the 2019-05 release!

## Audio editing

### Audacity

The latest version uses GTK3 and the UI elements scale in size nicely.  However, there are still some issues with fonts in some places, but it is totally usable.

1. Install the `audacity` package.
2. If you're using dark theme, it will look messed up at first.  Go to `Edit` → `Preferences` → `Interface` and change `Theme` to `Dark`.

I had trouble getting audio to work on the Lenovo P50.  None of the sound cards showed up in the list other than the ones over HDMI.  I think it is because Audacity uses ALSA and requires exclusive access, whereas my Arch Plasma setup uses PulseAudio as a software mixing layer and probably monopolized the devices.  Getting Audacity to use PulseAudio is a little wonky:

1. Install the `alsa-plugins` package.
2. In Audacity, keep the host set to `ALSA` and set the playback and recording devices to `pulse`.
3. It will use the default devices configured in PulseAudio by default.  To change, use `pavucontrol` or similar PulseAudio utility.

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

## Steam

1. Add `multilib` pacman repository.
2. 32-bit OpenGL drivers are also needed.  For AMD and Intel, install `lib32-mesa`, and for NVIDIA, install `lib32-nvidia-utils`.
3. The locale `en_US.UTF-8` is required and must be generated.  If you followed the instructions in this repository to install Arch Linux, you probably already have this locale unless you chose a different one.
4. Steam relies on Microsoft fonts; install `ttf-liberation` to get free substitutes.
5. Install `steam` package.

## Integrated Development Environment (IDE)

### IntelliJ IDEA

With the default setup, I have run into this error when trying to edit Markdown files: `Tried to use preview panel provider (JavaFX WebView), but it is unavailable. Reverting to default.`  Installing using this setup worked:

1. Install `intellij-idea-community-edition-no-jre` AUR package.
2. Install Java 8 (`jdk8-openjdk`).
3. Make sure optional dependency `java8-openjfx` is installed.
4. In IntelliJ, install the `Choose Runtime` plugin.
5. Use the plugin to select the 1.8 runtime.
