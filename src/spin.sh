#!/bin/bash
set -e

if [ "$USER" != "root" ]; then
    echo "Must run as root!"
    exit 1
fi

SPIN=/spin

FORCE=
LINK=
MOVE=
DIR=

while [ "$1" ]; do
    if [ "$1" == "--force" ]; then shift; FORCE=1;
    elif [ "$1" = "--link" ]; then shift; LINK=1;
    elif [ "$1" = "--move" ]; then shift; MOVE=1;
    elif [ "${1:0:1}" != "-" ]; then
        if [ "$DIR" != "" ]; then
            echo "Unrecognized parameter: $1"
            exit 1
        fi
        DIR=$1; 
        shift;
    else
        echo "Unrecognized parameter: $1"
        exit 1
    fi
done

if [ "$DIR" == "" ]; then
    echo "Usage: spin.sh [--force] [--link] [--move] directory"
    exit 1
fi

ABSDIR="$(cd "$DIR" >/dev/null 2>&1 && pwd)"
if [ "$ABSDIR" == "" ]; then
    echo "Directory does not exist: $DIR"
    exit 1
fi

if [ "${ABSDIR:0:1}" != "/" ]; then
    echo "Could not determine absolute path for: $DIR"
    exit 1
fi

if [ "$ABSDIR" == "/" ]; then
    echo "Cannot spin root!"
    exit 1
fi

DIR="$ABSDIR"

echo "Checking directories..."

declare -a PARTS
COUNT=0
while [ "$DIR" != "/" ]; do
    PARTS[COUNT]="$DIR"
    COUNT=$(( $COUNT + 1 ))
    DIR="$(dirname "$DIR")"
done

INDEX=$(( $COUNT - 1 ))
while [ $INDEX -ge 0 ]; do
    DIR="${PARTS[INDEX]}"
    SPINDIR="$SPIN$DIR"
    if [ ! -e "$SPINDIR" ]; then
        echo "$SPINDIR: Creating"
        mkdir "$SPINDIR"
    else
        echo "$SPINDIR: Already exists"
        if [ ! -d "$SPINDIR" ]; then
            echo "File already exists and is not a directory: $SPINDIR"
            exit 1
        fi
    fi
    
    if [ "$(stat -c '%f' "$SPINDIR")" != "$(stat -c '%f' "$DIR")" ]; then
        echo "$SPINDIR: Changing mode"
        chmod -v --reference="$DIR" "$SPINDIR"
    fi

    if [ "$(stat -c '%u:%g' "$SPINDIR")" != "$(stat -c '%u:%g' "$DIR")" ]; then
        echo "$SPINDIR: Changing owner"
        chown -v --reference="$DIR" "$SPINDIR"
    fi

    INDEX=$(( $INDEX - 1 ))
done

if [ $MOVE ]; then
    echo "Moving files..."
    echo "$DIR: Copying files recursively"
    cp -iprTv "$DIR" "$SPINDIR"

    echo "$DIR: Comparing files recursively"
    CODE=0
    diff -r "$DIR" "$SPINDIR" || CODE=$?

    if [ "$CODE" != "0" ]; then
        echo "Files differ!"
        if [ $FORCE ]; then
            echo "Continuing anyway due to --force flag"
        else
            exit 1
        fi
    fi

    echo "$DIR: Deleting files recursively"
    rm -rf "$DIR"
fi

if [ $LINK ]; then
    echo "Linking directories"
    ln -s "$SPINDIR" "$DIR"
fi
