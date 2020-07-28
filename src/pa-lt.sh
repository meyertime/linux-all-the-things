#!/bin/bash
set -e

HEADSET_MIC=alsa_input.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.mono-fallback
VOICE_SOURCE=voice_final.monitor

if [ "$SOURCE" == "" ]; then
    pactl list short sources \
        | grep $VOICE_SOURCE >/dev/null \
        && SOURCE=$VOICE_SOURCE \
        || SOURCE=$HEADSET_MIC
fi

HEADSET_OUT=alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo
WEBRTC_SINK=voice_webrtc

if [ "$SINK" == "" ]; then
    pactl list short sinks \
        | grep $WEBRTC_SINK >/dev/null \
        && SINK=$WEBRTC_SINK \
        || SINK=$HEADSET_OUT
fi

CLOCK_SINK=lt_clock
HOST_SINK=lt_host
RECORDER_SINK=lt_record
SILENCE_SINK=lt_silence

CLOCK_SOURCE=lt_clock_mic
RECORDER_SOURCE=lt_record_mic
SILENCE_SOURCE=lt_silence_mic

function setup {
    pactl load-module module-null-sink \
        sink_name=$CLOCK_SINK \
        sink_properties='device.description="LT\ Clock"'

    #pactl load-module module-null-sink \
    #    sink_name=$HOST_SINK \
    #    sink_properties='device.description="LT\ Host"'

    pactl load-module module-null-sink \
        sink_name=$RECORDER_SINK \
        sink_properties='device.description="LT\ Recorder"'

    pactl load-module module-null-sink \
        sink_name=$SILENCE_SINK \
        sink_properties='device.description="LT\ Silence"'

    pactl set-sink-mute $SILENCE_SINK 1

    pactl load-module module-virtual-source \
        source_name=$CLOCK_SOURCE \
        source_properties='device.description="LT\ Clock\ Mic"' \
        master=$CLOCK_SINK.monitor

    pactl load-module module-virtual-source \
        source_name=$RECORDER_SOURCE \
        source_properties='device.description="LT\ Recorder\ Mic"' \
        master=$RECORDER_SINK.monitor

    pactl load-module module-virtual-source \
        source_name=$RECORDER_SOURCE \
        source_properties='device.description="LT\ Silence\ Mic"' \
        master=$RECORDER_SINK.monitor

    #pactl load-module module-loopback \
    #    source=$SOURCE \
    #    sink=$HOST_SINK \
    #    source_dont_move=true \
    #    sink_dont_move=true \
    #    latency_msec=1

    #pactl load-module module-loopback \
    #    source=$CLOCK_SINK.monitor \
    #    sink=$HOST_SINK \
    #    source_dont_move=true \
    #    sink_dont_move=true

    #pactl load-module module-loopback \
    #    source=$CLOCK_SINK.monitor \
    #    sink=$SINK \
    #    source_dont_move=true \
    #    sink_dont_move=true
}

function cleanup {
    MODULES=$(pactl list short modules | grep -E '^[0-9]+\s+module-null-sink\s+sink_name=lt_' | sed -E 's/^([0-9]+).*$/\1/')

    while read MODULE; do
        if [ "$MODULE" != "" ]; then
            pactl unload-module $MODULE
        fi
    done <<<"$MODULES"
}

function defaults {
    pactl set-default-source $SOURCE
    pactl set-default-sink $SINK
}

function move-apps {
    OBS_SOURCE_OUTPUT=$(find-app-source-output OBS)
    pactl move-source-output $OBS_SOURCE_OUTPUT $RECORDER_SINK.monitor

    #FIREFOX_SOURCE_OUTPUT=$(find-app-source-output Firefox 2)
    FIREFOX_SINK_INPUT=$(find-app-sink-input Firefox 3)
    
    # Assume the first Firefox is the host hangout
    #HOST_SOURCE_OUTPUT=$(sed -n '1p' <<<"$FIREFOX_SOURCE_OUTPUT")
    HOST_SINK_INPUT=$(sed -n '1p' <<<"$FIREFOX_SINK_INPUT")

    # Assume the second Firefox is the recorder hangout
    #RECORDER_SOURCE_OUTPUT=$(sed -n '2p' <<<"$FIREFOX_SOURCE_OUTPUT")
    RECORDER_SINK_INPUT=$(sed -n '2p' <<<"$FIREFOX_SINK_INPUT")

    # Assume the third Firefox is the countdown clock
    CLOCK_SINK_INPUT=$(sed -n '3p' <<<"$FIREFOX_SINK_INPUT")

    #pactl move-source-output $HOST_SOURCE_OUTPUT $HOST_SINK.monitor
    pactl move-sink-input $HOST_SINK_INPUT $SINK
    
    #pactl move-source-output $RECORDER_SOURCE_OUTPUT $SILENCE_SINK.monitor
    pactl move-sink-input $RECORDER_SINK_INPUT $RECORDER_SINK

    pactl move-sink-input $CLOCK_SINK_INPUT $CLOCK_SINK

    echo 'Firefox/Hangouts will not let us change the mic inputs'
    echo 'Make the following changes manually:'
    echo '- Host mic to "Monitor of LT Host"'
    echo '- Recorder mic to "Monitor of LT Silence"'
    echo
    echo 'Firefox outputs may be mixed up too; if so:'
    echo '- Host playback to "Voice WebRTC" or your headphones/speaker'
    echo '- Recorder playback to "LT Recorder"'
    echo '- Clock playback to "LT Clock"'
}

function find-app-source-output {
    APP=$1
    EXPECT=${2:-1}
    RESULTS=$(pactl list source-outputs \
        | sed -E ':begin;$!N;s/\n\s+/\; /;tbegin' \
        | grep -E '^Source Output #[0-9]+.*?; application.name = "'$APP'"' \
        | sed -E 's/^Source Output #([0-9]+).*$/\1/' \
        || '')
    COUNT=$(grep -c '' <<<"$RESULTS")
    if [ "$RESULTS" == "" ]; then
        COUNT=0
    fi
    if [ $COUNT != $EXPECT ]; then
        echo "Could not find source output for $APP; expected $EXPECT, but found $COUNT" >&2
        exit 1
    fi
    echo "$RESULTS"
}

function find-app-sink-input {
    APP=$1
    EXPECT=${2:-1}
    RESULTS=$(pactl list sink-inputs \
        | sed -E ':begin;$!N;s/\n\s+/\; /;tbegin' \
        | grep -E '^Sink Input #[0-9]+.*?; application.name = "'$APP'"' \
        | sed -E 's/^Sink Input #([0-9]+).*$/\1/' \
        || '')
    COUNT=$(grep -c '' <<<"$RESULTS")
    if [ "$RESULTS" == "" ]; then
        COUNT=0
    fi
    if [ $COUNT != $EXPECT ]; then
        echo "Could not find sink input for $APP; expected $EXPECT, but found $COUNT" >&2
        exit 1
    fi
    echo "$RESULTS"
}

ACTION=$1
if [ "$ACTION" == "" ]; then
    ACTION=setup
fi

case $ACTION in

    setup)
        setup
        defaults
        #move-apps
        ;;

    cleanup)
        cleanup
        defaults
        ;;

    *)
        echo "Unrecognized action: $ACTION" >&2
        exit 1
        ;;

esac
