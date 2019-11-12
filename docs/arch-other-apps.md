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

## Git GUI client

- GitAhead - seems pretty full-featured, but has a strange interface...
- SmartGit - so far, seems to be the most fully-featured; however, it is only free for personal use and not open source.
- Gitg - really simple and no push functionality, but otherwise nice.
- Git Cola - seems really customizable and may be nice if I can get used to it, but I can't seem to find out how to see a simple list of commits that shows tree structure.
