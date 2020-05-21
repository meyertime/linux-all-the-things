#!/bin/bash

PID=
SIGNAL_PENDING=
function handle_signal {
    SIGNAL_PENDING=$1
    if [ $PID ]; then
        kill -$1 $PID
    fi
}

function wait_signal {
    if [ $SIGNAL_PENDING ]; then
        kill -$SIGNAL_PENDING $PID
    fi
    wait $PID
    trap - INT KILL
    wait $PID
}

trap 'handle_signal INT' INT
trap 'handle_signal KILL' KILL

echo '> openconnect' "$@"

GP_OKTA_DIR="/usr/local/lib/pan-globalprotect-okta"
GP_OKTA_CONF="$GP_OKTA_DIR/gp-okta.conf"
CSD_WRAPPER="$GP_OKTA_DIR/hipreport.sh"
EXTRA_ARGS="--os win"

ARGS=
GATEWAY=
STDIN=0

while [ "$1" ]; do
    if [ "$1" = "--syslog" ]; then shift; ARGS="$ARGS --syslog";
    elif [ "$1" = "--script" ]; then shift; ARGS="$ARGS --script \"$1\""; shift;
    elif [ "$1" = "--interface" ]; then shift; ARGS="$ARGS --interface \"$1\""; shift;
    elif [ "$1" = "--csd-wrapper" ]; then shift; CSD_WRAPPER="$1"; shift;
    elif [ "$1" = "--cookie-on-stdin" ]; then shift; STDIN=1;
    elif [ "$1" = "--passwd-on-stdin" ]; then shift; STDIN=1;
    elif [ "${1:0:1}" != "-" ]; then GATEWAY=$1; shift;
    else shift; fi
done

ARGS="$ARGS --csd-wrapper \"$CSD_WRAPPER\""
ARGS="$ARGS $EXTRA_ARGS"

if [ $STDIN = 1 ]; then read; fi
# Ignoring password or cookie input; if needed, it is now in the $REPLY variable

if [ $SIGNAL_PENDING ]; then exit; fi
PASSWORD=`DISPLAY=:0 kdialog --title "VPN" --password "Enter Okta password:"`
if [ $? != 0 ]; then exit $?; fi

if [ $SIGNAL_PENDING ]; then exit; fi
OUTPUT=$(GP_PASSWORD="$PASSWORD" GP_OPENCONNECT_CMD=openconnect.real GP_OPENCONNECT_ARGS="$ARGS" GP_EXECUTE=0 GP_OPENCONNECT_CERTS=/tmp/runtime-nm-openconnect/certs "$GP_OKTA_DIR/gp-okta.py" "$GP_OKTA_CONF")
if [ $? != 0 ]; then echo "$OUTPUT"; exit; fi

CMD=$(echo "$OUTPUT" | tail -n 1)
OUTPUT=$(echo "$OUTPUT" | head -n -1 | grep -E -v '^\[INFO\] (sessionToken|prelogin-cookie|portal-userauthcookie):')
echo "$OUTPUT"

if [ $SIGNAL_PENDING ]; then exit; fi
eval "$CMD &"
PID=$!

wait_signal
