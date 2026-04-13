#!/usr/bin/env python3
import json
import subprocess
import sys
from datetime import datetime, timezone

RESET  = "\x1b[0m"
GREEN  = "\x1b[32m"
YELLOW = "\x1b[33m"
RED    = "\x1b[31m"
DIM    = "\x1b[2m"
CYAN   = "\x1b[36m"
GRAY   = "\x1b[90m"
RATE_SEGMENTS = 10
BRAILLE = ' ⣀⣄⣤⣦⣶⣷⣿'


def color_for(pct):
    if pct < 50:
        return GREEN
    if pct < 80:
        return YELLOW
    return RED


def render_ctx_bar(pct, width=8):
    level = pct / 100
    chars = []
    for i in range(width):
        seg_start = i / width
        seg_end = (i + 1) / width
        if level >= seg_end:
            chars.append(BRAILLE[7])
        elif level <= seg_start:
            chars.append(BRAILLE[0])
        else:
            frac = (level - seg_start) / (seg_end - seg_start)
            chars.append(BRAILLE[int(frac * 7)])
    return f"{color_for(pct)}{''.join(chars)}{RESET}"


def render_rate_bar(pct, width=RATE_SEGMENTS):
    filled = min(width, round(pct / 100 * width))
    bar = "━" * filled + "╌" * (width - filled)
    return f"{color_for(pct)}{bar}{RESET}"


def format_reset_time(ts):
    if not ts:
        return ""
    dt = datetime.fromtimestamp(ts, tz=timezone.utc).astimezone()
    now = datetime.now().astimezone()
    if dt.date() == now.date():
        return "Resets " + dt.strftime("%-I%p").lower()
    return "Resets " + dt.strftime("%b %-d at %-I%p").lower()


def get_git_branch(cwd):
    try:
        result = subprocess.run(
            ["git", "-C", cwd, "branch", "--show-current"],
            capture_output=True, text=True, timeout=2,
        )
        return result.stdout.strip() or None
    except (subprocess.TimeoutExpired, OSError, FileNotFoundError):
        return None


def render_rate_limit_line(emoji, label, seg):
    pct = float(seg.get("used_percentage", 0))
    c = color_for(pct)
    bar = render_rate_bar(pct)
    reset = format_reset_time(seg.get("resets_at"))
    return f"{emoji} {DIM}{label}{RESET}   {bar}  {c}{pct:3.0f}%{RESET}  {DIM}{reset}{RESET}"


def main():
    try:
        raw = sys.stdin.read().strip()
        data = json.loads(raw) if raw else {}
    except (json.JSONDecodeError, OSError):
        data = {}

    lines = []

    parts = []

    model_name = (data.get("model") or {}).get("display_name")
    if model_name:
        parts.append(f"🤖 {CYAN}{model_name}{RESET}")

    ctx = data.get("context_window") or {}
    if ctx:
        ctx_pct = float(ctx.get("used_percentage", 0))
        parts.append(f"📊 {render_ctx_bar(ctx_pct)} {color_for(ctx_pct)}{ctx_pct:.0f}%{RESET}")

    cost = data.get("cost") or {}
    added   = cost.get("total_lines_added", 0)
    removed = cost.get("total_lines_removed", 0)
    if added or removed:
        parts.append(f"✏️  {GREEN}+{added}{RESET}/{RED}-{removed}{RESET}")

    cwd = data.get("cwd") or (data.get("workspace") or {}).get("current_dir")
    if cwd:
        branch = get_git_branch(cwd)
        if branch:
            parts.append(f"🔀 {branch}")

    if parts:
        lines.append(f" {GRAY}│{RESET} ".join(parts))

    rl = data.get("rate_limits") or {}
    for emoji, label, key in [("🕡️", "5h", "five_hour"), ("📅", "7d", "seven_day")]:
        seg = rl.get(key) or {}
        if seg:
            lines.append(render_rate_limit_line(emoji, label, seg))

    print("\n".join(lines) if lines else f"{DIM}no usage data{RESET}")


if __name__ == "__main__":
    main()
