# PulseAudio on Arch Linux

Like most things on Linux, audio is not a single built-in black-box system, but rather it is made up of multiple systems and it's really extensible.  It seems that ALSA is used to interact with sound devices directly.  Applications must take exclusive access of the sound devices, however.  That's where PulseAudio comes in.  This is basically a sound server that allows applications to share sound devices.

Some of the concepts to get a grasp of in PulseAudio are:

- Sink:  A "sink" is basically an output.  It's a place where you can send audio.  All audio sent to a sink is mixed together.  There may be a sink for your headphone jack, for example.  The mix of audio sent to the sink is then sent to the headphone output.
- Source:  A "source" is basically an input.  It's a place where you can get audio.  There may be a sink for your microphone, for example.  The audio picked up by the microphone is made available as a source.
- Monitor:  Each sink also has a "monitor" source.  Thus, the audio that is being sent to a sink can be accessed as a source through its monitor.  (Yeah, I know, this is where it gets confusing.)  Monitors are usually hidden from user interfaces, however, but you can use command line tools or more advanced GUIs (like PulseAudio Volume Control) to work with them.
- Null Sink:  Creating a "null sink" is handy sometimes for setting up different kinds of processing to happen in PulseAudio without having to use actual client applications.  It's just a sink with no actual physical hardware output associated with it.  Therefore, applications can send audio to it, and you can access that audio through its monitor source.
- Loopback:  This is another handy tool for setting up audio processing.  It simply takes audio from a source and feeds it to a sink.
- Module:  PulseAudio has various "modules" that you can load and unload to do different things.  Null sinks and loopbacks are both types of modules that you can load.  Other modules can do different things like process effects.

## Noise and echo cancellation

I have noticed that applications like Google Meet and Zoom do not perform as much audio processing as they do on Windows.  I am thinking this may be because these functions were built-in to Windows, and the developers did not put any effort into implementing something similar on Linux.  You can, however, not only achieve the same effect, but tune it to be even better on Linux using PulseAudio.

### Echo cancellation

PulseAudio has a built-in module for echo cancellation that uses WebRTC.  You'll see information about it floating around the internet.  It works OK for echo cancellation and filtering out constant noise like background whitenoise, but you will want more, which I'll get to later.

Basically:

```
# Create the echo cancellation module
pactl load-module module-echo-cancel \
    use_master_format=1 \
    source_master=$MIC_TO_CANCEL_ECHO_FROM \
    sink_master=$SPEAKER_THAT_MIGHT_FEED_BACK_TO_MIC \
    aec_method=webrtc \
    aec_args="analog_gain_control=0\ digital_gain_control=1" \
    source_name=$NEW_SOURCE_THAT_APPS_SHOULD_USE_INSTEAD \
    source_properties='device.description="Friendly\ name\ for\ the\ new\ source"' \
    sink_name=$NEW_SINK_THAT_APPS_SHOULD_USE_INSTEAD \
    sink_properties='device.description="Friendly\ name\ for\ the\ new\ sink"'

# You probably want to set the default source and sink
pactl set-default-source $NEW_SOURCE_THAT_APPS_SHOULD_USE_INSTEAD
pactl set-default-sink $NEW_SINK_THAT_APPS_SHOULD_USE_INSTEAD
```

### Noise gate

As mentioned, the above echo cancellation works OK for some kinds of noise, but you will want more.  For example, it does not filter things like typing, breathing, or other random noises that aren't speaking.  For this, I found a noise gate works well.

Install `ladspa` and `swh-plugins`, which is a collection of LADSPA audio effects, including some noise gates, which can be used by PulseAudio, among other things.  Then:

```
# Create a null sink that will be used to represent the final output that applications should use
pactl load-module module-null-sink \
    sink_name=$NEW_SINK_WHOSE_MONITOR_APPS_SHOULD_USE_INSTEAD \
    sink_properties='device.description="Friendly\ name\ for\ the\ new\ sink"'

# Create the noise gate LADSPA filter module
# This uses the null sink created above, not the sink you may have created for echo cancellation earlier
pactl load-module module-ladspa-sink \
    sink_name=$NEW_SINK_FOR_THE_NOISE_GATE \
    sink_properties='device.description="Friendly\ name\ for\ the\ noise\ gate\ sink"'
    sink_master=$NEW_SINK_WHOSE_MONITOR_APPS_SHOULD_USE_INSTEAD \
    plugin=gate_1410 \
    label=gate \
    control=500,4000,-48,10,90,250,-90,0

# Create the loopback to connect your microphone input to the noise gate
# If you set up echo cancellation earlier, you want to use the new source created for that
# By default, the latency is a little much, so setting `latency_msec=1` will try to minimize it
pactl load-module module-loopback \
    source=$MIC_SOURCE_OR_ECHO_CANCELLED_SOURCE \
    sink=$NEW_SINK_FOR_THE_NOISE_GATE \
    source_dont_move=true \
    sink_dont_move=true \
    latency_msec=1

# You probably want to set the default source
pactl set-default-source $NEW_SINK_WHOSE_MONITOR_APPS_SHOULD_USE_INSTEAD.monitor
```

## Making changes permanent

Thus far, we have used `pactl` to make changes to a running PulseAudio server.  However, none of these changes will persist across reboots.

You can create the file `~/.config/pulse/default.pa` to run commands when the PulseAudio server starts.  The file should start with `.include /etc/pulse/default.pa` so that system-wide defaults will still apply.  The commands in this script should be the same except without `pactl` at the beginning.  See [default.pa](../src/default.pa) in this repository which does some useful things.

Keep in mind that removable devices like USB headsets may not be available at the time the script is run.  To get around this, I wrote [pa-monitor.sh](../src/pa-monitor.sh), which uses `pactl` to watch for events from PulseAudio and react to them.  So for example, it automatically sets up the above echo cancellation and noise gate for my headset when I plug it in.  You can set it up to automatically start in KDE by using `System Settings` → `Startup and Shutdown` → `Autostart`, or simply copy or create a link to the script in `~/.config/autostart-scripts/`.

