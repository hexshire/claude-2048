# 2048 while Claude thinks

A tiny terminal game that pops up automatically while [Claude Code](https://claude.com/claude-code)
is busy thinking, so you stop drifting off to Twitter.

When you submit a prompt, a new Terminal window appears after a short delay with
a `curses`-based 2048 board. When Claude finishes its turn, the window closes
itself and brings focus back to your main terminal.

```
   ┌────┬────┬────┬────┐
   │  2 │    │  4 │  2 │
   ├────┼────┼────┼────┤
   │    │  8 │    │    │
   ├────┼────┼────┼────┤
   │  4 │ 16 │  2 │    │
   ├────┼────┼────┼────┤
   │    │    │  4 │  2 │
   └────┴────┴────┴────┘
   ←↑→↓ / hjkl: move    r: restart    q: quit
```

## How it works

Two Claude Code hooks are wired into `~/.claude/settings.json`:

| Event              | Script       | What it does                                                              |
| ------------------ | ------------ | ------------------------------------------------------------------------- |
| `UserPromptSubmit` | `launch.sh`  | Schedules a new Terminal window with 2048 to open after a 3-second delay. |
| `Stop`             | `stop.sh`    | Cancels the pending launch (if Claude was fast) and closes the window.    |

The 3-second delay means short responses don't cause a window to flicker open
and shut. State (pending PID, window title) is tracked in `/tmp/claude-2048/`.

## Requirements

- macOS (uses AppleScript via `osascript` to drive Apple Terminal)
- Python 3 (ships with macOS at `/usr/bin/python3`)
- Claude Code CLI installed and run from Apple Terminal

> The current launcher targets `Terminal.app`. iTerm2 isn't supported out of
> the box but the `osascript` block in `launch.sh` and `stop.sh` is the only
> thing you'd need to swap.

## Install

```sh
git clone <this-repo> ClaudeAdventure
cd ClaudeAdventure
./install.sh
```

`install.sh` is idempotent:

- Copies `2048.py`, `launch.sh`, `stop.sh` to `~/.claude/games/`
- Adds the two hooks to `~/.claude/settings.json` (skips if already present)

Start a new Claude Code session and send any prompt that takes more than a few
seconds. A new Terminal window should pop up with the game.

> The first time AppleScript opens a Terminal window, macOS may ask for
> permission to control Terminal. Approve it once and you're set.

## Usage

| Key                       | Action                          |
| ------------------------- | ------------------------------- |
| `←` `↑` `→` `↓`           | Move tiles                      |
| `h` `j` `k` `l`           | Move tiles (vim-style)          |
| `w` `a` `s` `d`           | Move tiles (gamer-style)        |
| `r`                       | Restart the board               |
| `q` or `Esc`              | Quit                            |

Your best score is persisted in `~/.claude/games/.2048_highscore`.

## Disable temporarily

Set an environment variable in the shell where you run `claude`:

```sh
export CLAUDE_NO_GAME=1
claude
```

The launcher exits early when this is set, so no window opens.

## Uninstall

```sh
./uninstall.sh
```

This removes the hook entries from `~/.claude/settings.json`, deletes
`~/.claude/games/`, and cleans up `/tmp/claude-2048/`.

## File layout

```
ClaudeAdventure/
├── 2048.py        # the game (curses, single file, stdlib only)
├── launch.sh      # UserPromptSubmit hook — opens the game window
├── stop.sh        # Stop hook — closes the game window
├── install.sh     # copies files + patches settings.json
├── uninstall.sh   # reverses install
└── README.md
```

## Customizing

- **Delay before launch.** Edit `DELAY_SECONDS` at the top of `launch.sh`.
- **Window position / size.** Tweak `set bounds of front window` inside the
  `osascript` block in `launch.sh`.
- **Board size.** Change `SIZE` near the top of `2048.py` (4 by default).
- **Colors.** Reorder `PALETTE` in `2048.py`.
