#!/bin/bash
set -e

# This script creates a new Wine prefix for the calling user.
# The base image must be built with sudo, which makes all created
# files and directories owned by root. During runtime, Wine does
# not allow a Wine prefix to be used by a different user.
# To solve this, we create a new user-owned Wine prefix and
# symlink its contents from the root-owned prefix, which has
# read/write/execute permissions set during the build.


WINE_PREFIXES_LOCATION="${WINE_PREFIXES_LOCATION:-/opt/wine-prefixes}"
WINEPREFIX="${WINEPREFIX:-$WINE_PREFIXES_LOCATION/tmnf}"   
USER_PREFIX="$WINE_PREFIXES_LOCATION/wine-$USER"

# the check has nothing do with the logic, its just a sanity check since the container should only use in32
if [ "$WINEARCH" != "win32" ]; then
    echo "ERROR: WINEARCH must be win32"
    exit 1
fi

if [ ! -d "$WINEPREFIX" ]; then
    echo "ERROR: Wine prefix not found: $WINEPREFIX"
    exit 1
fi

if [ ! -d "$USER_PREFIX" ]; then
    echo "Creating new Wine prefix for user: $USER"
    mkdir -p "$USER_PREFIX/drive_c/users"

    rsync -a --exclude 'drive_c' "$WINEPREFIX/" "$USER_PREFIX/"

    # Symlink everything in drive_c expect users
    for item in "$WINEPREFIX/drive_c/"*; do
        base="$(basename "$item")"

        if [ "$base" = "users" ]; then
            continue
        fi

        ln -s "$item" "$USER_PREFIX/drive_c/$base"
    done

    # Symlink root profile → user profile
    if [ -d "$WINEPREFIX/drive_c/users/root" ]; then
        ln -s "$WINEPREFIX/drive_c/users/root" "$USER_PREFIX/drive_c/users/$USER"
    else
        echo "WARNING: root user profile not found in shared prefix"
    fi
fi

chmod -R u+rwX "$USER_PREFIX" 2>/dev/null || true

export WINEPREFIX="$USER_PREFIX"
export WINEARCH

exec "$@"
