#!/usr/bin/env python3
"""What do I actually do, and how often?  Reads the local habit log (and old shell histories).

  scripts/habits.py            full report
  scripts/habits.py --days 14  only the last 14 days (needs the habit log)

Everything stays on this machine. Arguments are shown only for repeated commands, never for ones that
look like they carry a secret.
"""

import argparse
import collections
import datetime
import os
import re
import sys
import time
from pathlib import Path

HOME = Path.home()
LOG = (
    Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share")) / "habits/commands.tsv"
)
SECRET = re.compile(
    r"(token|passw|secret|api[_-]?key|bearer|authorization|ghp_|sk-|private.*key)", re.I
)


def load(days):
    """-> list of (epoch|None, rc|None, cwd|None, cmd). The habit log wins; old histories fill the past."""
    ev, seen_log = [], False
    if LOG.exists():
        seen_log = True
        for line in LOG.read_text(errors="ignore").splitlines():
            p = line.split("\t", 3)
            if len(p) == 4:
                ev.append((int(p[0]), int(p[1]), p[2], p[3]))
    if not seen_log or not days:
        ts = None
        for f in (HOME / ".bash_history",):
            if f.exists():
                for line in f.read_text(errors="ignore").splitlines():
                    if re.fullmatch(r"#\d{9,}", line):
                        ts = int(line[1:])
                    elif line.strip():
                        ev.append((ts, None, None, line.strip()))
                        ts = None
        fish = HOME / ".local/share/fish/fish_history"
        if fish.exists():
            for line in fish.read_text(errors="ignore").splitlines():
                if line.startswith("- cmd: "):
                    ev.append((None, None, None, line[7:].strip()))
    if days:
        cut = time.time() - days * 86400
        ev = [e for e in ev if e[0] and e[0] >= cut]
    return [e for e in ev if not SECRET.search(e[3])]


def first(cmd):
    cmd = re.sub(
        r"^(sudo\s+|time\s+|env\s+)?([A-Z_][A-Z0-9_]*=\S+\s+)*", "", cmd.strip()
    )
    return cmd.split()[0] if cmd.split() else ""


def aliases():
    """alias name -> expansion, from the shell modules."""
    out = {}
    for f in (HOME / "dotfiles/bashrc/.shell_modules").rglob("*.sh"):
        for m in re.finditer(
            r"^alias ([A-Za-z0-9_.-]+)=(['\"])(.*?)\2\s*$",
            f.read_text(errors="ignore"),
            re.M,
        ):
            out[m[1]] = m[3]
    return out


def bar(n, top, width=28):
    return "█" * max(1, round(n / top * width)) if top else ""


def digest(days=7):
    """A few lines for a notification: volume, the top habits, and the one suggestion worth acting on."""
    ev = load(days)
    if not ev:
        return ""
    cmds = [e[3] for e in ev]
    top = collections.Counter(first(c) for c in cmds)
    tops = ", ".join(f"{k} {100 * n // len(cmds)}%" for k, n in top.most_common(3))
    rc = [e for e in ev if e[1] is not None]
    fail = f", {100 * sum(1 for e in rc if e[1]) // len(rc)}% failed" if rc else ""
    al = aliases()
    expansions = collections.defaultdict(list)
    for k, v in al.items():
        expansions[v.strip()].append(k)
    typed = collections.Counter(c.strip() for c in cmds if c.strip() in expansions)
    tip = ""
    if typed:
        c, n = typed.most_common(1)[0]
        tip = f"\nTip: `{c[:36]}` typed in full {n}x, `{expansions[c][0]}` does it"
    return f"{len(cmds)} commands in {days} days{fail}\nMostly: {tops}{tip}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=0)
    ap.add_argument(
        "--digest", action="store_true", help="short summary for a notification"
    )
    a = ap.parse_args()
    if a.digest:
        print(digest(a.days or 7))
        return
    ev = load(a.days)
    if not ev:
        sys.exit(
            "no data yet: open a new shell and use it for a while (the log starts when habits.sh is sourced)"
        )
    cmds = [e[3] for e in ev]
    stamped = [e for e in ev if e[0]]
    span = ""
    if stamped:
        d0 = datetime.datetime.fromtimestamp(min(e[0] for e in stamped))
        d1 = datetime.datetime.fromtimestamp(max(e[0] for e in stamped))
        span = f", {d0:%b %d} to {d1:%b %d} ({max(1, (d1 - d0).days + 1)} days with stamps)"
    print(f"{len(ev)} commands{span}")
    print(
        f"source: {'habit log' if LOG.exists() else 'old shell histories only (log starts after the next shell)'}\n"
    )

    # ---- what
    top = collections.Counter(first(c) for c in cmds)
    print("== most used")
    mx = top.most_common(1)[0][1]
    for k, n in top.most_common(14):
        print(f"  {n:5d} {100 * n / len(cmds):4.1f}%  {k:<14} {bar(n, mx)}")

    # ---- failures (only with the habit log)
    rc = [e for e in ev if e[1] is not None]
    if rc:
        fails = collections.Counter(first(e[3]) for e in rc if e[1] != 0)
        tot = collections.Counter(first(e[3]) for e in rc)
        print("\n== failing most (exit status != 0)")
        for k, n in fails.most_common(8):
            print(f"  {n:5d} of {tot[k]:<5d} {k}")

    # ---- git
    gits = collections.Counter()
    for c in cmds:
        m = re.match(r"(?:sudo\s+)?git\s+(?:-C\s+\S+\s+)?([a-z-]+)", c)
        if m:
            gits[m[1]] += 1
    if gits:
        print(f"\n== git is {100 * sum(gits.values()) / len(cmds):.0f}% of everything")
        print("  " + ", ".join(f"{k} {n}" for k, n in gits.most_common(8)))

    # ---- aliases
    al = aliases()
    used = {k for k in al if top.get(k)}
    expansions = collections.defaultdict(list)
    for k, v in al.items():
        expansions[v.strip()].append(k)
    typed_long = collections.Counter()
    for c in cmds:
        if c.strip() in expansions:
            typed_long[c.strip()] += 1
    print(f"\n== aliases: {len(al)} defined, {len(used)} used at all")
    if typed_long:
        print("  typed in full although an alias exists:")
        for c, n in typed_long.most_common(6):
            print(f"    {n:4d}x  {c[:44]:<44} -> {', '.join(expansions[c])}")

    # ---- repeats and sequences
    rep = collections.Counter(c for c in cmds if len(c) >= 12)
    reps = [(c, n) for c, n in rep.most_common(10) if n >= 3]
    if reps:
        print("\n== repeated 3+ times (shortcut candidates)")
        for c, n in reps:
            print(f"  {n:4d}x  {c[:78]}")
    pairs = collections.Counter()
    for x, y in zip(cmds, cmds[1:]):
        fx, fy = first(x), first(y)
        if fx and fy and fx != fy:
            pairs[(fx, fy)] += 1
    print("\n== what follows what")
    for (x, y), n in pairs.most_common(6):
        print(f"  {n:4d}  {x} -> {y}")

    # ---- when / where
    if stamped:
        hrs = collections.Counter(
            datetime.datetime.fromtimestamp(e[0]).hour for e in stamped
        )
        mx = max(hrs.values())
        print("\n== by hour")
        print(
            "  "
            + " ".join(
                f"{h:02d}:{'#' * max(1, round(hrs[h] / mx * 8)) if hrs[h] else '.'}"
                for h in range(24)
                if hrs[h]
            )
        )
    dirs = collections.Counter(e[2] for e in ev if e[2])
    if dirs:
        print("\n== where (directories)")
        for d, n in dirs.most_common(6):
            print(f"  {n:5d}  {d.replace(str(HOME), '~')}")

    # ---- suggestions, derived from the numbers above
    print("\n== suggestions")
    s = []
    if typed_long:
        c, n = typed_long.most_common(1)[0]
        s.append(
            f"you typed `{c[:40]}` in full {n}x though `{expansions[c][0]}` exists: shorter, more guessable names would help"
        )
    if len(al) and len(used) < len(al) * 0.25:
        s.append(
            f"{len(al) - len(used)} of {len(al)} aliases never used on this machine: prune or document them (check your other machines first)"
        )
    if pairs.get(("cd", "ls"), 0) + pairs.get(("ls", "cd"), 0) > 15:
        s.append(
            "cd and ls alternate a lot: make `cd` zoxide-smart and list the directory after jumping"
        )
    if reps:
        s.append(f"`{reps[0][0][:40]}` repeated {reps[0][1]}x: give it a one-word name")
    print("  " + ("\n  ".join(f"- {x}" for x in s) if s else "none yet"))


if __name__ == "__main__":
    main()
