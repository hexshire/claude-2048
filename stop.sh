#!/bin/bash
# Hook: Stop
# Cancels the pending launch (if Claude responded before the delay) and closes
# the game window to bring focus back to the user's main terminal.

STATE_DIR="/tmp/claude-2048"

# Cancel pending launch (if the window hasn't opened yet due to the delay).
if [ -f "$STATE_DIR/pending-pid" ]; then
    PID=$(cat "$STATE_DIR/pending-pid")
    kill "$PID" 2>/dev/null
    pkill -P "$PID" 2>/dev/null
    rm -f "$STATE_DIR/pending-pid"
fi

# Close the game window if it's open.
if [ -f "$STATE_DIR/window-id" ]; then
    SESSION_ID=$(cat "$STATE_DIR/window-id")
    /usr/bin/osascript >/dev/null 2>&1 <<EOF
tell application "Terminal"
    set winList to every window
    repeat with w in winList
        try
            if custom title of w is "$SESSION_ID" then
                close w saving no
            end if
        end try
    end repeat
end tell
EOF
    rm -f "$STATE_DIR/window-id"
fi
exit 0
