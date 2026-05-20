#!/bin/bash
# Hook: UserPromptSubmit
# Opens 2048 in a new Terminal window after a short delay.
# If Claude responds before the delay elapses, stop.sh cancels the pending launch.

STATE_DIR="/tmp/claude-2048"
GAME="$HOME/.claude/games/2048.py"
DELAY_SECONDS=3

mkdir -p "$STATE_DIR"

# Escape hatch: CLAUDE_NO_GAME=1 disables the game without touching settings.json.
if [ -n "$CLAUDE_NO_GAME" ]; then
    exit 0
fi

# If a window is already open or a launch is already pending, do nothing.
if [ -f "$STATE_DIR/window-id" ] || [ -f "$STATE_DIR/pending-pid" ]; then
    exit 0
fi

(
    sleep "$DELAY_SECONDS"
    SESSION_ID="claude-2048-$$-$(date +%s)"
    echo "$SESSION_ID" > "$STATE_DIR/window-id"
    rm -f "$STATE_DIR/pending-pid"

    /usr/bin/osascript >/dev/null 2>&1 <<EOF
tell application "Terminal"
    activate
    do script "clear; exec /usr/bin/env python3 '$GAME'; exit"
    set custom title of front window to "$SESSION_ID"
    set bounds of front window to {320, 160, 880, 700}
end tell
EOF
) &
echo $! > "$STATE_DIR/pending-pid"
disown
exit 0
