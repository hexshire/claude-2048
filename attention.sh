#!/bin/bash
# Hook: Notification
# Fires when Claude needs the user's input (permission prompt, question, idle).
# Flips the game into "Claude needs you" mode by writing a flag the game polls.

STATE_DIR="/tmp/claude-2048"
mkdir -p "$STATE_DIR"

touch "$STATE_DIR/needs-attention"

# Bring the game window to the front so the banner is visible.
if [ -f "$STATE_DIR/window-id" ]; then
    SESSION_ID=$(cat "$STATE_DIR/window-id")
    /usr/bin/osascript >/dev/null 2>&1 <<EOF
tell application "Terminal"
    activate
    try
        set index of (first window whose custom title is "$SESSION_ID") to 1
    end try
end tell
EOF
fi

# Native macOS notification and gentle chime.
/usr/bin/osascript -e 'display notification "Claude is waiting for your input" with title "Claude Code"' >/dev/null 2>&1 &
afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1 &
disown
exit 0
