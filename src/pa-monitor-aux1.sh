#!/bin/bash

HEADPHONE_AMP=alsa_output.usb-CMEDIA_OriGen_G2-00.analog-stereo
HEADSET_MIC=alsa_input.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.
HEADSET_EAR=alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.
MIXER_REC=alsa_input.usb-Burr-Brown_from_TI_USB_Audio_CODEC-00.analog-stereo
AUX1_SINK=aux1_sink
AUX1_SOURCE=aux1_sink.monitor

SINKS=
#SINK_INPUTS=
SOURCES=
#MODULES=

function read-all {
    SINKS=$(pactl list sinks)
    #SINK_INPUTS=$(pactl list sink-inputs)
    SOURCES=$(pactl list sources)
    #MODULES=$(pactl list short modules)
}

function find-sink {
    #echo "$SINKS" | grep -m 1 -E "^[0-9]+\s+$1\s" | sed -E 's/^([0-9]+).*$/\1/'
    find-thing "$SINKS" Sink "$1" "$2"
}

function find-source {
    #echo "$SOURCES" | grep -m 1 -E "^[0-9]+\s+$1\s" | sed -E 's/^([0-9]+).*$/\1/'
    find-thing "$SOURCES" Source "$1" "$2"
}

function find-thing {
    INPUT=$1
    TYPE=$2
    NAME=$3
    CONDITION=$4
    RESULTS=$(echo "$INPUT" \
        | sed -E ':begin;$!N;s/\n\s+/\; /;tbegin' \
        | grep -E "^$TYPE #[0-9]+.*?; Name: $NAME" \
        | grep -E "^$TYPE #[0-9]+.*?; $CONDITION" \
        | sed -E "s/^$TYPE #([0-9]+).*$/\1/" \
        || '')
    COUNT=$(grep -c '' <<<"$RESULTS")
    if [ "$RESULTS" == "" ]; then
        COUNT=0
    fi
    if [ $COUNT != 0 ]; then
        echo "${RESULTS[0]}"
    fi
}

read-all

#SOURCE=$(find-source $AUX1_SOURCE)
#SINK=$(find-sink $HEADPHONE_AMP)

pactl load-module module-loopback \
    source=$(find-source $MIXER_REC) \
    sink=$(find-sink $AUX1_SINK) \
    source_dont_move=true \
    sink_dont_move=true \
    latency_msec=1

pactl load-module module-loopback \
    source=$(find-source $HEADSET_MIC) \
    sink=$(find-sink $AUX1_SINK) \
    source_dont_move=true \
    sink_dont_move=true \
    latency_msec=1

pactl load-module module-loopback \
    source=$(find-source $MIXER_REC) \
    sink=$(find-sink $HEADSET_EAR) \
    source_dont_move=true \
    sink_dont_move=true \
    latency_msec=1
