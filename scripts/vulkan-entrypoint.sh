#!/bin/bash -e

# rm -rf /tmp/.X*

export PATH="${PATH}:/opt/VirtualGL/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}"

# Logs
LOG_FILE=/tmp/logs
mkdir -p "$LOG_FILE"
chmod 700 "$LOG_FILE"

export DISPLAY=":0"
Xorg -noreset -novtswitch -nolisten tcp +extension GLX +extension RANDR +extension RENDER -logfile "$LOG_FILE/xorg.log" -config /etc/X11/xorg.conf "$DISPLAY" &

# Wait for X11 socket
echo "Waiting for X socket..."
until [ -S "/tmp/.X11-unix/X${DISPLAY/:/}" ]; do sleep 1; done
echo "X socket is ready"

# Start window manager
nohup fluxbox >/dev/null 2>&1 < /dev/null &
echo "Fluxbox started."
sleep 1

echo "Session Running."

exec "$@"
