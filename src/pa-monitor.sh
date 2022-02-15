#!/bin/bash

BUILT_IN_OUT=alsa_output.pci-0000_00_1f.3.analog-stereo
BUILT_IN_OUT_DESC="Built-in"
BUILT_IN_MIC=alsa_input.pci-0000_00_1f.3.analog-stereo
BUILT_IN_MIC_DESC="Built-in"

HEADPHONE_AMP=alsa_output.usb-CMEDIA_OriGen_G2-00.analog-stereo
HEADPHONE_AMP_DESC="OriGen"

HEADSET_MIC=alsa_input.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.
HEADSET_MIC_DESC="Headset Raw"
HEADSET_EAR=alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.
HEADSET_EAR_DESC="Headset"

WEBCAM_MIC=alsa_input.usb-046d_0821_A8E00BD0-00.analog-stereo
WEBCAM_MIC_DESC="Webcam"

HDMI_OUT=alsa_output.pci-0000_01_00.1.hdmi-stereo-extra1
HDMI_OUT_DESC="Video Card"

SINKS=
SINK_INPUTS=
SOURCES=
MODULES=

function read-all {
    SINKS=$(pactl list sinks)
    SINK_INPUTS=$(pactl list sink-inputs)
    SOURCES=$(pactl list sources)
    MODULES=$(pactl list short modules)
}

function on-new {
    on-change

    #sleep 1

    rename-sink $BUILT_IN_OUT "$BUILT_IN_OUT_DESC"
    rename-source $BUILT_IN_MIC "$BUILT_IN_MIC_DESC"
    rename-sink $HEADPHONE_AMP "$HEADPHONE_AMP_DESC"
    rename-source $HEADSET_MIC "$HEADSET_MIC_DESC"
    rename-sink $HEADSET_EAR "$HEADSET_EAR_DESC"
    rename-source $WEBCAM_MIC "$WEBCAM_MIC_DESC"
    rename-sink $HDMI_OUT "$HDMI_OUT_DESC"

    SOURCE=$(find-source $HEADSET_MIC)
    if [ "$SOURCE" != "" ]; then
        SINK=$(find-sink $HEADSET_EAR)
        if [ "$SINK" != "" ]; then
            setup-gate headset Headset $SOURCE $SINK
        fi
    fi

    #on-change
}

function on-remove {
    (if-source $HEADSET_MIC && if-sink $HEADSET_EAR) || cleanup-gate headset Headset
}

function on-change {
    MUTE_SINK=$(find-sink mute_sink '.*(front-left: [1-9]|front-right: [1-9])')
    if [ "$MUTE_SINK" != "" ]; then
        echo "Mute sink non-zero volume detected!  Zeroing..."
        pactl set-sink-volume $MUTE_SINK 0
    fi

    #MUTE_SINK=$(find-sink mute_sink 'Mute: no')
    #if [ "$MUTE_SINK" != "" ]; then
    #    echo "Mute sink unmute detected!  Muting..."
    #    pactl set-sink-mute $MUTE_SINK 1
    #fi

    MUTE_SOURCE=$(find-source mute_source '.*(front-left: [1-9]|front-right: [1-9])')
    if [ "$MUTE_SOURCE" != "" ]; then
        echo "Mute source non-zero volume detected!  Zeroing..."
        pactl set-source-volume $MUTE_SOURCE 0
    fi

    MUTE_SOURCE=$(find-source mute_source 'Mute: no')
    if [ "$MUTE_SOURCE" != "" ]; then
        echo "Mute source unmute detected!  Muting..."
        pactl set-source-mute $MUTE_SOURCE 1
    fi

    SUB_SINK_INPUTS=$(find-sink-inputs '.*Volume: (mono|front-left|front-right): (?!0|65536)[0-9]+.*media.name = "AudioStream"')
    while read SINK_INPUT; do
        if [ "$SINK_INPUT" != "" ]; then
            echo "Sink input $SINK_INPUT below full volume detected!  Maxing..."
            pactl set-sink-input-volume $SINK_INPUT 65536
        fi
    done <<<"$SUB_SINK_INPUTS"
}

function find-sink {
    #echo "$SINKS" | grep -m 1 -E "^[0-9]+\s+$1\s" | sed -E 's/^([0-9]+).*$/\1/'
    find-thing "$SINKS" Sink "$1" "$2"
}

function find-sink-inputs {
    INPUT=$SINK_INPUTS
    TYPE="Sink Input"
    CONDITION=$1
    RESULTS=$(echo "$INPUT" \
        | sed -E ':begin;$!N;s/\n\s+/\; /;tbegin' \
        | grep -P "^$TYPE #[0-9]+.*?; $CONDITION" \
        | sed -E "s/^$TYPE #([0-9]+).*$/\1/" \
        || '')
    echo "$RESULTS"
}

function find-source {
    #echo "$SOURCES" | grep -m 1 -E "^[0-9]+\s+$1\s" | sed -E 's/^([0-9]+).*$/\1/'
    find-thing "$SOURCES" Source "$1" "$2"
}

function find-module {
    echo "$MODULES" | grep -m 1 -E "^[0-9]+\s+module-$1\s+.*?($2)" | sed -E 's/^([0-9]+).*$/\1/'
    #find-thing "$MODULES" Module "$1" "$2"
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

function rename-sink {
    SINK=$(find-sink $1)
    if [ "$SINK" != "" ]; then
        echo "$2 sink detected!  Renaming..."
        pacmd update-sink-proplist $SINK "device.description=\"$2\""
    fi
}

function rename-source {
    SOURCE=$(find-source $1)
    if [ "$SOURCE" != "" ]; then
        echo "$2 source detected!  Renaming..."
        pacmd update-source-proplist $SOURCE "device.description=\"$2\""
    fi
}

function if-sink {
    SINK=$(find-sink $1)
    if [ "$SINK" == "" ]; then
        return 1
    fi
}

function if-source {
    SOURCE=$(find-source $1)
    if [ "$SOURCE" == "" ]; then
        return 1
    fi
}

function if-module {
    MODULE=$(find-module $1 "$2")
    if [ "$MODULE" == "" ]; then
        return 1
    fi
}

function setup-rtc {
    NAME=$1
    DESC=$2
    SOURCE=$3
    SINK=$4

    echo "$DESC detected!  Setting up RTC..."

    WEBRTC_SINK=${NAME}_rtc
    WEBRTC_SOURCE=${NAME}_rtc_source

    if-module echo-cancel "source_master=$SOURCE" || (
        pactl load-module module-echo-cancel \
            use_master_format=1 \
            source_master=$SOURCE \
            sink_master=$SINK \
            aec_method=webrtc \
            aec_args="analog_gain_control=0\ digital_gain_control=1" \
            source_name=$WEBRTC_SOURCE \
            sink_name=$WEBRTC_SINK \
            sink_properties="device.description=\"$DESC\"" \
            source_properties="device.description=\"$DESC\ RTC\ Output\""

        #pactl set-default-sink $WEBRTC_SINK
    )

    setup-gate $NAME $DESC $WEBRTC_SOURCE $SINK
}

function cleanup-rtc {
    NAME=$1
    DESC=$2

    echo "$DESC no longer detected!  Cleaning up RTC..."

    MODULES=$(echo "$MODULES" | grep -E "^[0-9]+\s+module-(echo-cancel\s+(sink|source)_name=${NAME}_)" | sed -E 's/^([0-9]+).*$/\1/')

    while read MODULE; do
        if [ -n "$MODULE" ]; then
            pactl unload-module $MODULE
        fi
    done <<<"$MODULES"

    cleanup-gate
}

function setup-gate {
    NAME=$1
    DESC=$2
    SOURCE=$3
    SINK=$4

    echo "$DESC detected!  Setting up noise gate..."

    GATE_SINK=${NAME}_gate
    GATE_SOURCE=${NAME}_gate.monitor
    FINAL_SINK=${NAME}_final
    FINAL_MONITOR=${NAME}_final.monitor
    FINAL_SOURCE=${NAME}_final_source

    if-module null-sink sink_name=$FINAL_SINK || (
        pactl load-module module-null-sink \
            sink_name=$FINAL_SINK \
            sink_properties="device.description=\"$DESC\ Gate\ Output\""
    )

    # Gate control parameters:
    # 0. LF key filter (Hz) - Controls the cutoff of the low frequency filter (highpass).
    # 1. HF key filter (Hz) - Controls the cutoff of the high frequency filter (lowpass).
    # 2. Threshold (dB) - Controls the level at which the gate will open.
    # 3. Attack (ms) - Controls the time the gate will take to open fully.
    # 4. Hold (ms) - Controls the minimum time the gate will stay open for.
    # 5. Decay (ms) - Controls the time the gate will take to close fully.
    # 6. Range (dB) - Controls the difference between the gate's open and closed state.
    # 7. Output select (-1 = key listen, 0 = gate, 1 = bypass) - Controls output monitor. -1 is the output of the key filters (so you can check what is being gated on). 0 is the normal, gated output. 1 is bypass mode. 
    if-module ladspa-sink sink_name=$GATE_SINK || (
        pactl load-module module-ladspa-sink \
            sink_name=$GATE_SINK \
            sink_master=$FINAL_SINK \
            plugin=gate_1410 \
            label=gate \
            control=500,10000,-54,5,90,250,-90,0 \
            sink_properties="device.description=\"$DESC\ Gate\ Input\""
    )

    if-module loopback sink=$GATE_SINK || (
        pactl load-module module-loopback \
            source=$SOURCE \
            sink=$GATE_SINK \
            source_dont_move=true \
            sink_dont_move=true \
            latency_msec=1
    )

    if-module virtual-source source_name=$FINAL_SOURCE || (
        pactl load-module module-virtual-source \
            source_name=$FINAL_SOURCE \
            source_properties="device.description=\"$DESC\"" \
            master=$FINAL_MONITOR

        pactl set-default-source $FINAL_SOURCE
    )

    if [ "$MONITOR" == "1" ]; then
        if-module loopback source=$FINAL_SOURCE || (
            pactl load-module module-loopback \
                source=$FINAL_SOURCE \
                sink=$SINK \
                source_dont_move=true \
                sink_dont_move=true \
                latency_msec=1
        )
    fi
}

function cleanup-gate {
    NAME=$1
    DESC=$2

    echo "$DESC no longer detected!  Cleaning up noise gate..."

    MODULES=$(echo "$MODULES" | grep -E "^[0-9]+\s+module-((null-sink|ladspa-sink|virtual-source)\s+(sink|source)_name=${NAME}_)" | sed -E 's/^([0-9]+).*$/\1/')

    while read MODULE; do
        if [ -n "$MODULE" ]; then
            pactl unload-module $MODULE
        fi
    done <<<"$MODULES"
}

function read-events {
    read-all
    on-new

    while IFS= read -r line; do
        EVENT=$(echo "$line" \
            | grep -E "Event '.+?' on (sink|sink-input|source) #" \
            | sed -E "s/^Event '(.+?)'.*\$/\1/")
        if [ -n "$EVENT" ]; then
            echo "$line"
            read-all
            "on-$EVENT"
        fi
    done
}

CODE=0
while true; do
    echo "Subscribing to PulseAudio events..."
    pactl subscribe | read-events
    CODE=$?
    echo "Exited with code $CODE"
    if [ $CODE != 0 ]; then
        echo "Non-zero exit code!  Aborting!"
        break
    fi
    echo "Zero exit code.  Will retry after 1 second..."
    sleep 1
done
