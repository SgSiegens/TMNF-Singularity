#!/bin/bash
set -e

SHARED_PREFIX="/opt/tmnf"
USER_PREFIX="$HOME/.wine"

# Protect host's real .wine directory
if [ -d "$USER_PREFIX" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "ERROR: A '.wine' directory already exists in your home."
    echo "It looks like you are mounting your HOST home directory."
    echo "To protect your files, this script will not continue."
    echo "PLEASE: Run Singularity with '--no-home' or delete $USER_PREFIX"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

# Only if it doesn't exist
if [ ! -d "$USER_PREFIX" ]; then
    echo "Setting up instant symlinked prefix for user: $USER"
    
    # Create the base structure
    mkdir -p "$USER_PREFIX/drive_c/users"
    
    # Copy the small metadata/registry files (must be writable)
    rsync -a --exclude 'drive_c' "$SHARED_PREFIX/" "$USER_PREFIX/"

    # We link everything EXCEPT 'users' so heavy data stays in /opt
    for item in "$SHARED_PREFIX/drive_c/"*; do
        basename=$(basename "$item")
        
        if [ "$basename" == "users" ]; then
            continue
        fi
        
        # Create the symlink in our local drive_c pointing to /opt/tmnf
        ln -s "$item" "$USER_PREFIX/drive_c/$basename"
    done

    # We symlink the pre-built 'root' profile to the current $USER name.
    ln -s "$SHARED_PREFIX/drive_c/users/root" "$USER_PREFIX/drive_c/users/$USER"
fi

export WINEPREFIX="$USER_PREFIX"
export WINEARCH=win32

chmod -R u+rwX "$USER_PREFIX" 2>/dev/null || true

echo "Wine Prefix ready at $WINEPREFIX"
exec "$@"
