"""The habit logger, exercised in a real interactive bash (pty) with the user's real history settings
(erasedups + ignoredups), which are exactly what makes naive loggers lose repeated commands.
"""

import os
import pathlib
import pty
import select
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "bashrc/.shell_modules/tools/habits.sh"


def run_session(commands):
    home = tempfile.mkdtemp()
    env = {
        "HOME": home,
        "TERM": "dumb",
        "PATH": os.environ["PATH"],
        "XDG_DATA_HOME": home + "/data",
        "PS1": "$ ",
    }
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe("/bin/bash", ["bash", "--norc", "--noprofile", "-i"], env)

    def drain(t=0.3):
        end = time.time() + t
        while time.time() < end:
            if select.select([fd], [], [], 0.05)[0]:
                try:
                    os.read(fd, 65536)
                except OSError:
                    return

    def run(c):
        os.write(fd, (c + "\n").encode())
        drain()

    drain(0.5)
    run("export HISTCONTROL=ignoreboth:erasedups HISTTIMEFORMAT='%F %T '")
    run(f"source {SRC}")
    for c in commands:
        run(c)
    run("exit")
    log = pathlib.Path(home, "data/habits/commands.tsv")
    rows = [l.split("\t") for l in log.read_text().splitlines()] if log.exists() else []
    return home, [(int(r[1]), r[2], r[3]) for r in rows]


def test_logger():
    home, rows = run_session(
        [
            "echo one",
            "false",
            "echo one",
            "echo one",
            "ls /nonexistent_dir_x",
            "echo mytoken=abc",
            " echo hidden",
            "cd /tmp",
            "echo two",
            "",
        ]
    )
    cmds = [c for _, _, c in rows]
    assert cmds.count("echo one") == 3, rows  # repeats are not lost
    assert (1, rows[1][1], "false") in rows or any(
        c == "false" and rc == 1 for rc, _, c in rows
    )
    assert any(c.startswith("ls /nonexistent") and rc == 2 for rc, _, c in rows)
    assert not any("token" in c for c in cmds)  # secret-looking is skipped
    assert not any("hidden" in c for c in cmds)  # a leading space means "don't record"
    assert any(c == "echo two" and d == "/tmp" for _, d, c in rows)
    assert all(
        c == c.strip() and not c[:1].isdigit() for c in cmds
    ), cmds  # no history number prefix
    assert oct(os.stat(home + "/data/habits").st_mode & 0o777) == "0o700"


def _session_output(setup, commands):
    """Like run_session but returns everything the terminal printed after the setup."""
    home = tempfile.mkdtemp()
    env = {
        "HOME": home,
        "TERM": "dumb",
        "PATH": os.environ["PATH"],
        "XDG_DATA_HOME": home + "/data",
        "PS1": "$ ",
    }
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe("/bin/bash", ["bash", "--norc", "--noprofile", "-i"], env)
    out = []

    def drain(t=0.3, keep=False):
        end = time.time() + t
        while time.time() < end:
            if select.select([fd], [], [], 0.05)[0]:
                try:
                    d = os.read(fd, 65536).decode(errors="replace")
                except OSError:
                    return
                if keep:
                    out.append(d)

    drain(0.5)
    for c in setup:
        os.write(fd, (c + "\n").encode())
        drain()
    for c in commands:
        os.write(fd, (c + "\n").encode())
        drain(0.35, keep=True)
    os.write(fd, b"exit\n")
    return home, "".join(out)


def test_alias_nudge_once_per_session():
    nav = ROOT / "bashrc/.shell_modules/tools/navigation.sh"
    home, out = _session_output(
        ["alias p='echo pushed'", f"source {SRC}"],
        ["echo pushed", "echo pushed", "echo pushed"],
    )
    assert out.count("you can type: p") == 1, out  # hinted once, not on every repeat


def test_no_nudge_for_the_alias_itself_or_failures():
    home, out = _session_output(["alias gg='false'", f"source {SRC}"], ["false", "gg"])
    assert "you can type" not in out, out  # a failing command is not nudged


def test_listing_after_cd():
    d = tempfile.mkdtemp()
    for n in ("alpha.txt", "beta.txt"):
        pathlib.Path(d, n).write_text("x")
    nav = ROOT / "bashrc/.shell_modules/tools/navigation.sh"
    home, out = _session_output(
        ["shopt -s expand_aliases", f"source {nav}"], [f"cd {d}"]
    )
    assert "alpha.txt" in out and "beta.txt" in out, out
