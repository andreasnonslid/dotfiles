#!/usr/bin/env python3
"""List this directory's just recipes, most used first (from the habit log), for a fuzzy picker.
Prints:  recipe<TAB>description"""
import collections
import os
import re
import subprocess
import sys
from pathlib import Path

log = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "habits/commands.tsv"
used = collections.Counter()
if log.exists():
    for line in log.read_text(errors="ignore").splitlines():
        p = line.split("\t", 3)
        if len(p) == 4:
            m = re.match(r"(?:j|just)\s+([A-Za-z0-9_-]+)", p[3])
            if m:
                used[m[1]] += 1
try:
    out = subprocess.run(["just", "--list", "--unsorted"], capture_output=True, text=True, check=True).stdout
except (OSError, subprocess.CalledProcessError):
    sys.exit(1)
rows = []
for line in out.splitlines()[1:]:
    m = re.match(r"\s+([A-Za-z0-9_-]+)((?:\s+\S+)*?)(?:\s+#\s+(.*))?$", line)
    if m:
        rows.append((m[1], (m[2] or "").strip(), (m[3] or "").strip()))
rows.sort(key=lambda r: -used[r[0]])
for name, params, doc in rows:
    print(f"{name}\t{params + '  ' if params else ''}{doc}".rstrip())
