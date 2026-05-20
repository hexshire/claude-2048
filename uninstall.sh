#!/bin/bash
# Uninstalls the 2048-while-Claude-thinks game.
#
# - Removes the hook entries from ~/.claude/settings.json
# - Deletes ~/.claude/games/ (game files + saved highscore)
# - Cleans up any leftover state in /tmp/claude-2048

set -euo pipefail

GAMES_DIR="$HOME/.claude/games"
SETTINGS_FILE="$HOME/.claude/settings.json"
STATE_DIR="/tmp/claude-2048"

if [ -f "$SETTINGS_FILE" ]; then
    echo "==> Removing hooks from $SETTINGS_FILE"
    /usr/bin/env python3 - "$SETTINGS_FILE" "$GAMES_DIR" <<'PYEOF'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
games_dir = Path(sys.argv[2])
settings = json.loads(settings_path.read_text())

commands_to_drop = {
    str(games_dir / "launch.sh"),
    str(games_dir / "stop.sh"),
}

hooks = settings.get("hooks", {})
for event, entries in list(hooks.items()):
    pruned_entries = []
    for entry in entries:
        kept = [h for h in entry.get("hooks", []) if h.get("command") not in commands_to_drop]
        if kept:
            entry["hooks"] = kept
            pruned_entries.append(entry)
    if pruned_entries:
        hooks[event] = pruned_entries
    else:
        del hooks[event]

if not hooks:
    settings.pop("hooks", None)

settings_path.write_text(json.dumps(settings, indent=2) + "\n")
PYEOF
fi

if [ -d "$GAMES_DIR" ]; then
    echo "==> Removing $GAMES_DIR"
    rm -rf "$GAMES_DIR"
fi

if [ -d "$STATE_DIR" ]; then
    echo "==> Cleaning up $STATE_DIR"
    rm -rf "$STATE_DIR"
fi

echo
echo "Done."
