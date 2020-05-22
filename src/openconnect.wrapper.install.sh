#!/bin/bash

echo 'Installing openconnect wrapper for NetworkManager integration'

LINK=/usr/bin/openconnect
WRAPPER=/usr/bin/openconnect.wrapper.sh
REAL=/usr/bin/openconnect.real

if [ -L $LINK ]; then
    echo "$LINK is already a link; skipping"
    exit
fi

if [ ! -f $LINK ]; then
    echo "$LINK does not exist; skipping"
    exit
fi

if [ ! -f $WRAPPER ]; then
    echo "$WRAPPER does not exist; skipping"
    exit
fi

mv -f $LINK $REAL
ln -s $WRAPPER $LINK

echo 'Done!'
