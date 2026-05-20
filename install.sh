#!/bin/bash
# Installs the 2048-while-Claude-thinks game.
#
# - Copies game files to ~/.claude/games/
# - Registers UserPromptSubmit + Stop hooks in ~/.claude/settings.json
#
# Safe to run multiple times: existing hooks for these scripts are not duplicated.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAMES_DIR="$HOME/.claude/games"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "==> Installing game files to $GAMES_DIR"
mkdir -p "$GAMES_DIR"
cp "$REPO_DIR/2048.py" "$GAMES_DIR/2048.py"
cp "$REPO_DIR/launch.sh" "$GAMES_DIR/launch.sh"
cp "$REPO_DIR/stop.sh" "$GAMES_DIR/stop.sh"
chmod +x "$GAMES_DIR/2048.py" "$GAMES_DIR/launch.sh" "$GAMES_DIR/stop.sh"

echo "==> Registering hooks in $SETTINGS_FILE"
/usr/bin/env python3 - "$SETTINGS_FILE" "$GAMES_DIR" <<'PYEOF'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
games_dir = Path(sys.argv[2])

if settings_path.exists():
    settings = json.loads(settings_path.read_text())
else:
    settings = {}

hooks = settings.setdefault("hooks", {})


def ensure_hook(event: str, command: str) -> bool:
    """Add the hook if it isn't already registered. Returns True if added."""
    entries = hooks.setdefault(event, [])
    for entry in entries:
        for h in entry.get("hooks", []):
            if h.get("command") == command:
                return False
    entries.append({"hooks": [{"type": "command", "command": command}]})
    return True


changed = False
changed |= ensure_hook("UserPromptSubmit", str(games_dir / "launch.sh"))
changed |= ensure_hook("Stop", str(games_dir / "stop.sh"))

if changed:
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(json.dumps(settings, indent=2) + "\n")
    print("  hooks added")
else:
    print("  hooks already present, nothing to do")
PYEOF

echo
echo "Done. Start Claude Code in a new shell and send a prompt to try it."
echo "Set CLAUDE_NO_GAME=1 to disable temporarily without uninstalling."
