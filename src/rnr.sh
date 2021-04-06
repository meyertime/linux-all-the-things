#!/bin/bash
#set -e

#echo "rnr $@" >>/tmp/rnr.log
#env >>/tmp/rnr.log

#echo "jakdajbirojekwlfnedkwanvdksapbnjiroe"

# Workaround for running as udev
export DISPLAY=:0
export XAUTHORITY=/home/david/.Xauthority

#xrandr 2>&1 >>/tmp/rnr.log

LAPTOP=eDP-1-1
THUNDERBOLT1=DP-4
THUNDERBOLT2=DP-5
DISPLAYPORT=DP-3
HDMI=DP-1

DOCKDP1=DP-4.2
DOCKDP2=DP-4.3

INT=${INT:-$LAPTOP}
EXT1=${EXT1:-$DOCKDP1}
EXT2=${EXT2:-$THUNDERBOLT2}

INTEL=eDP-1

SDDM=
DEBOUNCE=

function init()
{
    xrandr --newmode "3200x1800_60.00"  492.00  3200 3456 3800 4400  1800 1803 1808 1865 -hsync +vsync
    xrandr --addmode $INT 3200x1800_60.00

    xrandr --newmode "2880x1620_60.00"  396.25  2880 3096 3408 3936  1620 1623 1628 1679 -hsync +vsync
    xrandr --addmode $INT 2880x1620_60.00
}

function nvidiaDisableAllTransforms()
{
    # Prevents RRSetScreenSize error later on
    xrandr \
        --output $EXT1 --transform none \
        --output $EXT2 --transform none \
        --output $HDMI --transform none \
        --output $INT --transform none || true
}

function nvidiaUHDMobileProfile()
{
    #nvidiaDisableAllTransforms

    xrandr \
        --output $EXT1 --off \
        --output $EXT2 --off \
        --output $HDMI --off \
        --output $INT --mode 3200x1800_60.00 --pos 0x0 --primary
}

function nvidiaUHDDockedProfile()
{
    #nvidiaDisableAllTransforms

    if [ "$SDDM" == "1" ]; then
        for i in {1..3}; do
            xrandr \
                --output $EXT1 --mode 3840x2160 --pos 0x0 \
                --output $EXT2 --mode 3840x2160 --pos 0x0 --primary \
                --output $INT --mode 3840x2160 --transform none --pos 0x0 \
                --output $HDMI --off \
                && break || sleep 5
        done
    else
        for i in {1..3}; do
            xrandr \
                --output $EXT1 --mode 3840x2160 --pos 0x0 --panning 3840x2160+0+0 \
                --output $EXT2 --mode 3840x2160 --pos 0x2160 --panning 3840x2160+0+2160 --primary \
                --output $INT --mode 2880x1620_60.00 --pos 3840x2700 \
                --output $HDMI --off \
                && break || sleep 5
        done
    fi
}

function intelProfile()
{
    xrandr --output $INTEL --mode 3200x1800
}

function nvidiaTopProfile()
{
    xrandr \
        --output $EXT1 --mode 3840x2160 --pos 0x0 --panning 3840x2160+0+0 --primary \
        --output $EXT2 --off \
        --output $INT --off \
        --output $HDMI --off
}

# If running from udev rule, fork and run in separate process
if [ "$HOTPLUG" == "1" ]; then
    if [ ! -e /tmp/rnr.lock ]; then
        touch /tmp/rnr.lock
        #( ( HOTPLUG= "${BASH_SOURCE[0]}" debounce ) >>/tmp/rnr.log 2>&1 ) &
        #disown
        #HOTPLUG= "${BASH_SOURCE[0]}" debounce >>/tmp/rnr.log 2>&1

        #setsid bash -c "HOTPLUG= \"${BASH_SOURCE[0]}\" debounce >>/tmp/rnr.log 2>&1" &
    fi
    exit
fi

PROFILE=$1

if [ "$PROFILE" == "" ]; then
    PROFILE=auto
fi

if [ "$PROFILE" == "debounce" ]; then
    DEBOUNCE=1
    PROFILE=auto
fi

if [ "$PROFILE" == "sddm" ]; then
    SDDM=1
    PROFILE=auto
fi

if [ "$PROFILE" == "auto" ]; then
    PROFILE=
    MONITORS=$(xrandr --query | grep '\bconnected\b' | awk '{print $1}')
    NL=$'\n'
    if [ "$MONITORS" == "$INT" ]; then PROFILE=mobile; fi
    if [ "$MONITORS" == "$HDMI$NL$EXT2$NL$INT" ]; then PROFILE=docked; fi
    if [ "$MONITORS" == "$EXT2$NL$EXT1$NL$INT" ]; then PROFILE=docked; fi
    if [ "$MONITORS" == "$EXT1$NL$EXT2$NL$INT" ]; then PROFILE=docked; fi
    if [ "$MONITORS" == "$INTEL" ]; then PROFILE=intel; fi

    if [ "$PROFILE" == "" ]; then
        echo "Could not detect profile!"
    else
        echo "Detected profile: $PROFILE"

        if [ "$DEBOUNCE" == "1" ]; then
            echo "Debouncing"
            sleep 5
        fi
    fi
fi

case $PROFILE in

    init)
        init
        ;;

    mobile)
        nvidiaUHDMobileProfile
        ;;

    docked)
        nvidiaUHDDockedProfile
        ;;

    intel)
        intelProfile
        ;;

    top)
        nvidiaTopProfile
        ;;
esac

if [ "$DEBOUNCE" == "1" ]; then
    if [ "$PROFILE" != "" ]; then
        sleep 5
        echo "Debounced"
    fi
    rm -f /tmp/rnr.lock
fi
