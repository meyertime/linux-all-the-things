#!/bin/bash

CURRENT=$(qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl brightness)
MIN=1
MAX=$(qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl brightnessMax)
STEPS=20
MICROSTEPS=200
STEPPERCENT=10

# Equal steps:
#let DIFF=MAX-MIN
#let STEP=DIFF/STEPS
#let HALFSTEP=STEP/2
#let X=CURRENT-MIN
#let X=X*STEPS
#let X=X+HALFSTEP
#let X=X/DIFF
#let X=X+$1
#let X=X*DIFF
#let X=X/STEPS
#let X=X+MIN

# Or a percentage:
let DIFF=MAX-MIN
let X=$1*$STEPPERCENT
let X=100+X
let X=CURRENT*X
let X=X/100
# OK, so a percentage gets too granular at low brightness levels, so let's use a minimum step size:
let MICROSTEP=DIFF/MICROSTEPS
let DELTA=X-CURRENT
if [ $DELTA -lt $MICROSTEP ]; then
    if [ $DELTA -gt "-$MICROSTEP" ]; then
        if [ $DELTA -lt "0" ]; then DELTA=-$MICROSTEP;
        else DELTA=$MICROSTEP; fi
        let X=CURRENT+DELTA
    fi
fi

# Apply minimum and maximum:
if [ $X -lt $MIN ]; then X=$MIN; fi
if [ $X -gt $MAX ]; then X=$MAX; fi
NEW=$X

# Actually change the brightness:
qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl setBrightness $NEW
