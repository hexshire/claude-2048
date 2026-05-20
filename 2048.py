#!/usr/bin/env python3
"""2048 — a tiny terminal game to play while Claude is thinking."""
import curses
import math
import random
from pathlib import Path

SIZE = 4
CELL_W = 7
CELL_H = 3
HIGHSCORE_FILE = Path.home() / ".claude" / "games" / ".2048_highscore"


def load_highscore():
    try:
        return int(HIGHSCORE_FILE.read_text().strip())
    except Exception:
        return 0


def save_highscore(score):
    try:
        HIGHSCORE_FILE.write_text(str(score))
    except Exception:
        pass


def empty_cells(grid):
    return [(r, c) for r in range(SIZE) for c in range(SIZE) if grid[r][c] == 0]


def spawn(grid):
    cells = empty_cells(grid)
    if not cells:
        return False
    r, c = random.choice(cells)
    grid[r][c] = 4 if random.random() < 0.1 else 2
    return True


def slide_left(row):
    new = [x for x in row if x != 0]
    score = 0
    i = 0
    while i < len(new) - 1:
        if new[i] == new[i + 1]:
            new[i] *= 2
            score += new[i]
            del new[i + 1]
        i += 1
    new += [0] * (SIZE - len(new))
    return new, score


def move(grid, direction):
    original = [row[:] for row in grid]
    score = 0
    if direction == "left":
        for r in range(SIZE):
            grid[r], s = slide_left(grid[r])
            score += s
    elif direction == "right":
        for r in range(SIZE):
            new, s = slide_left(grid[r][::-1])
            grid[r] = new[::-1]
            score += s
    elif direction == "up":
        for c in range(SIZE):
            col = [grid[r][c] for r in range(SIZE)]
            new, s = slide_left(col)
            for r in range(SIZE):
                grid[r][c] = new[r]
            score += s
    elif direction == "down":
        for c in range(SIZE):
            col = [grid[r][c] for r in range(SIZE)][::-1]
            new, s = slide_left(col)
            new = new[::-1]
            for r in range(SIZE):
                grid[r][c] = new[r]
            score += s
    return grid != original, score


def is_game_over(grid):
    if empty_cells(grid):
        return False
    for r in range(SIZE):
        for c in range(SIZE):
            if c + 1 < SIZE and grid[r][c] == grid[r][c + 1]:
                return False
            if r + 1 < SIZE and grid[r][c] == grid[r + 1][c]:
                return False
    return True


def has_won(grid):
    return any(cell >= 2048 for row in grid for cell in row)


PALETTE = [
    (curses.COLOR_WHITE, -1),                    # 1: empty
    (curses.COLOR_BLACK, curses.COLOR_WHITE),    # 2: value 2
    (curses.COLOR_BLACK, curses.COLOR_WHITE),    # 3: value 4
    (curses.COLOR_WHITE, curses.COLOR_YELLOW),   # 4: value 8
    (curses.COLOR_WHITE, curses.COLOR_YELLOW),   # 5: value 16
    (curses.COLOR_WHITE, curses.COLOR_RED),      # 6: value 32
    (curses.COLOR_WHITE, curses.COLOR_RED),      # 7: value 64
    (curses.COLOR_BLACK, curses.COLOR_CYAN),     # 8: value 128
    (curses.COLOR_BLACK, curses.COLOR_CYAN),     # 9: value 256
    (curses.COLOR_BLACK, curses.COLOR_GREEN),    # 10: value 512
    (curses.COLOR_BLACK, curses.COLOR_GREEN),    # 11: value 1024
    (curses.COLOR_WHITE, curses.COLOR_MAGENTA),  # 12: value 2048 and up
]


def init_colors():
    curses.start_color()
    try:
        curses.use_default_colors()
    except Exception:
        pass
    for i, (fg, bg) in enumerate(PALETTE, start=1):
        try:
            curses.init_pair(i, fg, bg)
        except Exception:
            pass


def attr_for(v):
    if v == 0:
        return curses.color_pair(1)
    idx = min(int(math.log2(v)) + 1, len(PALETTE))
    return curses.color_pair(idx) | curses.A_BOLD


def draw(stdscr, grid, score, highscore, message):
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    board_w = CELL_W * SIZE + SIZE + 1
    board_h = CELL_H * SIZE + SIZE + 1
    y0 = max(0, (h - board_h - 7) // 2)
    x0 = max(0, (w - board_w) // 2)

    title = "  2048  "
    try:
        stdscr.addstr(y0, x0, title.center(board_w), curses.A_BOLD)
        stdscr.addstr(y0 + 1, x0, f"Score: {score}".ljust(board_w // 2))
        stdscr.addstr(y0 + 1, x0 + board_w // 2, f"Best: {highscore}")
    except curses.error:
        pass

    by = y0 + 3
    for r in range(SIZE):
        for c in range(SIZE):
            v = grid[r][c]
            cy = by + r * (CELL_H + 1)
            cx = x0 + c * (CELL_W + 1)
            attr = attr_for(v)
            for dy in range(CELL_H):
                try:
                    stdscr.addstr(cy + dy, cx, " " * CELL_W, attr)
                except curses.error:
                    pass
            label = str(v) if v else ""
            try:
                stdscr.addstr(
                    cy + CELL_H // 2,
                    cx + (CELL_W - len(label)) // 2,
                    label,
                    attr,
                )
            except curses.error:
                pass

    hy = by + board_h + 1
    try:
        stdscr.addstr(hy, x0, "←↑→↓ / hjkl: move    r: restart    q: quit")
        if message:
            stdscr.addstr(hy + 1, x0, message, curses.A_BOLD | curses.A_BLINK)
    except curses.error:
        pass

    stdscr.refresh()


def new_game():
    grid = [[0] * SIZE for _ in range(SIZE)]
    spawn(grid)
    spawn(grid)
    return grid


KEYMAP = {
    curses.KEY_LEFT: "left",
    curses.KEY_RIGHT: "right",
    curses.KEY_UP: "up",
    curses.KEY_DOWN: "down",
    ord("h"): "left",
    ord("l"): "right",
    ord("k"): "up",
    ord("j"): "down",
    ord("a"): "left",
    ord("d"): "right",
    ord("w"): "up",
    ord("s"): "down",
}


def run(stdscr):
    curses.curs_set(0)
    stdscr.keypad(True)
    init_colors()

    grid = new_game()
    score = 0
    highscore = load_highscore()
    message = ""
    won_shown = False

    while True:
        if score > highscore:
            highscore = score
            save_highscore(highscore)
        draw(stdscr, grid, score, highscore, message)
        ch = stdscr.getch()

        if ch in (ord("q"), 27):
            break
        if ch == ord("r"):
            grid = new_game()
            score = 0
            message = ""
            won_shown = False
            continue
        if ch in KEYMAP:
            changed, gained = move(grid, KEYMAP[ch])
            if changed:
                score += gained
                spawn(grid)
                if has_won(grid) and not won_shown:
                    message = "You won! Keep playing or press r to restart."
                    won_shown = True
                elif is_game_over(grid):
                    message = "Game over. Press r to restart, q to quit."
                else:
                    message = ""


if __name__ == "__main__":
    try:
        curses.wrapper(run)
    except KeyboardInterrupt:
        pass
