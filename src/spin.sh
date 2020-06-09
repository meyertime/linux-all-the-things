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
REVERSE=
DIR=

while [ "$1" ]; do
    if [ "$1" == "--force" ]; then shift; FORCE=1;
    elif [ "$1" = "--link" ]; then shift; LINK=1;
    elif [ "$1" = "--move" ]; then shift; MOVE=1;
    elif [ "$1" = "--reverse" ]; then shift; REVERSE=1;
    elif [ "${1:0:1}" != "-" ]; then
        if [ "$DIR" != "" ]; then
            echo "Error: Unrecognized parameter: $1"
            exit 1
        fi
        DIR=$1; 
        shift;
    else
        echo "Error: Unrecognized parameter: $1"
        exit 1
    fi
done

if [ "$DIR" == "" ]; then
    echo "Usage: spin.sh [--force] [--link] [--move] [--reverse] directory"
    exit 1
fi

ABSDIR="$(cd "$DIR" >/dev/null 2>&1 && pwd || true)"
if [ "$ABSDIR" == "" ]; then
    echo "Error: Directory does not exist: $DIR"
    exit 1
fi

if [ "${ABSDIR:0:1}" != "/" ]; then
    echo "Error: Could not determine absolute path for: $DIR"
    exit 1
fi

if [ "$ABSDIR" == "/" ]; then
    echo "Error: Cannot spin root!"
    exit 1
fi

DIR="$ABSDIR"
SPINDIR="$SPIN$DIR"

function check()
{
    echo "Checking directories..."

    if [ ! -e "$DIR" ]; then
        echo "Error: Canonical path does not exist: $DIR"
        exit 1
    fi

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

        if [ ! -d "$DIR" ]; then
            echo "Canonical path is not a directory; skipping: $DIR"
            break
        fi

        if [ ! -e "$SPINDIR" ]; then
            echo "$SPINDIR: Creating"
            mkdir "$SPINDIR"
        else
            echo "$SPINDIR: Already exists"
            if [ ! -d "$SPINDIR" ]; then
                echo "Error: File already exists and is not a directory: $SPINDIR"
                exit 1
            fi
        fi
        
        if [ -L "$DIR" ]; then
            TARGET=$(readlink "$DIR")
            if [ "$TARGET" == "$SPINDIR" ]; then
                echo "$SPINDIR: Already linked"
                break
            else
                echo "Error: $SPINDIR linked to wrong target: $TARGET"
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
}

function move()
{
    if [ $MOVE ]; then
        SRC="$DIR"
        DEST="$SPINDIR"
        if [ $REVERSE ]; then
            SRC="$SPINDIR"
            DEST="$DIR"
        fi

        echo "Moving files..."
        echo "$DIR: Copying files recursively"
        cp -iprTv "$SRC" "$DEST"

        echo "$DIR: Comparing files recursively"
        CODE=0
        diff -r "$SRC" "$DEST" || CODE=$?

        if [ "$CODE" != "0" ]; then
            if [ $FORCE ]; then
                echo "Files differ!  Continuing anyway due to --force flag"
            else
                echo "Error: Files differ!"
                exit 1
            fi
        fi

        echo "$SRC: Deleting files recursively"
        rm -rf "$SRC"
    fi
}

function link()
{
    if [ $LINK ]; then
        if [ $REVERSE ]; then
            echo "Unlinking directories"
            if [ -e "$DIR" ]; then
                unlink "$DIR"
            fi
            mkdir "$DIR"
        else
            echo "Linking directories"
            if [ -d "$DIR" ]; then
                rmdir "$DIR"
            fi

            if [ -e "$DIR" ]; then
                echo "Error: File already exists: $DIR"
            fi

            ln -sT "$SPINDIR" "$DIR"
        fi
    fi
}

function cleanup()
{
    echo "Cleaning up spin directories..."

    while [ "$DIR" != "/" ]; do
        SPINDIR="$SPIN$DIR"
        if [ -d "$SPINDIR" ]; then
            if [ ! "$(ls -A "$SPINDIR")" ]; then
                echo "$SPINDIR: Removing empty directory"
                rmdir "$SPINDIR"
            fi
        fi

        DIR="$(dirname "$DIR")"
    done
}

if [ $REVERSE ]; then
    link
    move
    cleanup
else
    check
    move
    link
fi
