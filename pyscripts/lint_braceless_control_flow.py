#!/usr/bin/env python3
"""Find braceless control flow (if/else/for/while) in a git branch diff.

Scans added lines for patterns like:
    if (cond)
        statement;

where the body is missing {}.

Usage:
    lint_braceless_control_flow.py [base-ref] [--ext .cpp .h ...]
    lint_braceless_control_flow.py                          # diff vs origin/master, C/C++ files
    lint_braceless_control_flow.py origin/develop            # diff vs origin/develop
    lint_braceless_control_flow.py HEAD~5 --ext .py          # last 5 commits, Python files
    lint_braceless_control_flow.py --all                     # scan working tree, not just diff
"""

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_EXTENSIONS = [".c", ".cpp", ".cc", ".cxx", ".h", ".hpp", ".hh", ".hxx"]

CTRL_FLOW_RE = re.compile(
    r"^(\s*)"
    r"(if\s*\(.*\)|else\s+if\s*\(.*\)|while\s*\(.*\)|for\s*\(.*\))"
    r"\s*$"
)
ELSE_RE = re.compile(r"^(\s*)else\s*$")


@dataclass
class Finding:
    file: str
    line: int
    control: str
    body: str
    is_guard: bool = False


@dataclass
class Stats:
    total: int = 0
    guards: int = 0
    by_file: dict = field(default_factory=dict)


def git_root() -> str:
    return subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], text=True
    ).strip()


def git_merge_base(ref: str) -> str:
    return subprocess.check_output(
        ["git", "merge-base", ref, "HEAD"], text=True
    ).strip()


def git_diff(base: str, extensions: list[str]) -> str:
    globs = [f"*{ext}" for ext in extensions]
    cmd = ["git", "diff", f"{base}...HEAD", "--"] + globs
    return subprocess.check_output(cmd, text=True)


def is_guard_body(body_stripped: str) -> bool:
    return bool(re.match(r"^(return\b|break\b|continue\b)", body_stripped))


def scan_diff(diff_text: str) -> list[Finding]:
    findings = []
    current_file = None
    hunk_line = 0
    lines = diff_text.split("\n")

    i = 0
    while i < len(lines):
        line = lines[i]

        if line.startswith("+++ b/"):
            current_file = line[6:]
            i += 1
            continue

        hunk_match = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
        if hunk_match:
            hunk_line = int(hunk_match.group(1))
            i += 1
            continue

        is_added = line.startswith("+") and not line.startswith("+++")
        is_removed = line.startswith("-") and not line.startswith("---")

        if is_added:
            code = line[1:]
            ctrl = CTRL_FLOW_RE.match(code) or ELSE_RE.match(code)
            if ctrl:
                j = i + 1
                while j < len(lines):
                    nxt = lines[j]
                    if nxt.startswith("-") and not nxt.startswith("---"):
                        j += 1
                        continue
                    nxt_code = nxt[1:] if nxt.startswith("+") else nxt
                    nxt_stripped = nxt_code.strip()
                    if not nxt_stripped or nxt_stripped.startswith("//"):
                        break
                    if nxt_stripped.startswith("{"):
                        break
                    body_stripped = nxt_stripped
                    findings.append(Finding(
                        file=current_file,
                        line=hunk_line,
                        control=code.rstrip(),
                        body=nxt_code.rstrip(),
                        is_guard=is_guard_body(body_stripped),
                    ))
                    break
                    j += 1

            hunk_line += 1
        elif not is_removed:
            hunk_line += 1

        i += 1

    return findings


def scan_files(extensions: list[str]) -> list[Finding]:
    """Scan entire working tree instead of a diff."""
    root = Path(git_root())
    findings = []
    for ext in extensions:
        for fpath in root.rglob(f"*{ext}"):
            rel = str(fpath.relative_to(root))
            try:
                file_lines = fpath.read_text(errors="replace").splitlines()
            except OSError:
                continue
            for i, line in enumerate(file_lines):
                ctrl = CTRL_FLOW_RE.match(line) or ELSE_RE.match(line)
                if ctrl and i + 1 < len(file_lines):
                    nxt = file_lines[i + 1]
                    nxt_stripped = nxt.strip()
                    if not nxt_stripped or nxt_stripped.startswith("//") or nxt_stripped.startswith("{"):
                        continue
                    findings.append(Finding(
                        file=rel,
                        line=i + 1,
                        control=line.rstrip(),
                        body=nxt.rstrip(),
                        is_guard=is_guard_body(nxt_stripped),
                    ))
    return findings


def print_findings(findings: list[Finding]) -> Stats:
    stats = Stats()
    by_file: dict[str, list[Finding]] = {}
    for f in findings:
        by_file.setdefault(f.file, []).append(f)

    for filepath, file_findings in sorted(by_file.items()):
        print(f"\n\033[1;36m{filepath}\033[0m ({len(file_findings)} instances)")
        for f in file_findings:
            tag = " \033[33m[guard]\033[0m" if f.is_guard else ""
            print(f"  \033[90mline {f.line}\033[0m{tag}")
            print(f"    {f.control}")
            print(f"    {f.body}")
        stats.by_file[filepath] = len(file_findings)
        stats.guards += sum(1 for f in file_findings if f.is_guard)

    stats.total = len(findings)
    return stats


def main():
    parser = argparse.ArgumentParser(
        description="Find braceless control flow in git branch diff"
    )
    parser.add_argument(
        "base", nargs="?", default="origin/master",
        help="Base ref to diff against (default: origin/master)",
    )
    parser.add_argument(
        "--ext", nargs="+", default=DEFAULT_EXTENSIONS,
        help=f"File extensions to check (default: {' '.join(DEFAULT_EXTENSIONS)})",
    )
    parser.add_argument(
        "--all", action="store_true", dest="scan_all",
        help="Scan entire working tree, not just branch diff",
    )
    parser.add_argument(
        "--no-color", action="store_true",
        help="Disable colored output",
    )
    args = parser.parse_args()

    if args.no_color:
        # Strip ANSI by monkey-patching (keeps logic simple)
        import functools
        _orig_print = print
        _ansi_re = re.compile(r"\033\[[0-9;]*m")

        @functools.wraps(_orig_print)
        def _plain_print(*a, **kw):
            a = tuple(_ansi_re.sub("", str(x)) for x in a)
            _orig_print(*a, **kw)

        import builtins
        builtins.print = _plain_print

    if args.scan_all:
        print(f"Scanning working tree for braceless control flow ({', '.join(args.ext)})...")
        findings = scan_files(args.ext)
    else:
        base = git_merge_base(args.base)
        print(f"Scanning diff {args.base} ({base[:10]})...HEAD for braceless control flow")
        diff = git_diff(base, args.ext)
        findings = scan_diff(diff)

    if not findings:
        print("\nNo braceless control flow found.")
        sys.exit(0)

    stats = print_findings(findings)

    print(f"\n\033[1mTotal: {stats.total}\033[0m instances "
          f"({stats.guards} guard clauses, "
          f"{stats.total - stats.guards} other) "
          f"across {len(stats.by_file)} files")
    sys.exit(1)


if __name__ == "__main__":
    main()
