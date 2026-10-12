"""rr (run-on-save) and jj (recipe picker list)."""
import os
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent


def test_rr_runs_python_and_passes_args():
    d = tempfile.mkdtemp()
    f = pathlib.Path(d, "t.py")
    f.write_text("import sys; print('got', sys.argv[1:])\n")
    r = subprocess.run([str(ROOT / "scripts/rr"), str(f), "a", "b"], capture_output=True, text=True)
    assert r.returncode == 0 and "got ['a', 'b']" in r.stdout


def test_rr_reports_failure_exit_code():
    d = tempfile.mkdtemp()
    f = pathlib.Path(d, "t.py")
    f.write_text("import sys; sys.exit(3)\n")
    r = subprocess.run([str(ROOT / "scripts/rr"), str(f)], capture_output=True, text=True)
    assert r.returncode == 3 and "exit 3" in r.stdout


def test_rr_rejects_unknown_language():
    d = tempfile.mkdtemp()
    f = pathlib.Path(d, "t.xyz")
    f.write_text("x")
    r = subprocess.run([str(ROOT / "scripts/rr"), str(f)], capture_output=True, text=True)
    assert r.returncode != 0


def test_rr_compiles_cpp():
    if subprocess.run(["which", "g++"], capture_output=True).returncode:
        return
    d = tempfile.mkdtemp()
    f = pathlib.Path(d, "t.cpp")
    f.write_text('#include <cstdio>\nint main(){printf("hi cpp\\n");}\n')
    r = subprocess.run([str(ROOT / "scripts/rr"), str(f)], capture_output=True, text=True)
    assert "hi cpp" in r.stdout and r.returncode == 0


def test_jj_orders_by_use():
    if subprocess.run(["which", "just"], capture_output=True).returncode:
        return
    d = tempfile.mkdtemp()
    pathlib.Path(d, "justfile").write_text("a:\n    echo a\nb:\n    echo b\nc:\n    echo c\n")
    data = pathlib.Path(d, "data/habits")
    data.mkdir(parents=True)
    data.joinpath("commands.tsv").write_text("1\t0\t/x\tjust c\n2\t0\t/x\tj c\n3\t0\t/x\tjust b\n")
    env = dict(os.environ, XDG_DATA_HOME=d + "/data")
    out = subprocess.run(["python3", str(ROOT / "scripts/jj.py")], cwd=d, env=env, capture_output=True, text=True).stdout
    assert [l.split("\t")[0] for l in out.splitlines()] == ["c", "b", "a"], out


def test_digest_is_weekly_and_needs_data():
    d = tempfile.mkdtemp()
    home = pathlib.Path(d)
    data = home / ".local/share/habits"
    data.mkdir(parents=True)
    import time
    now = int(time.time())
    rows = [f"{now - 5 * 86400 + i}\t0\t/x\tgit push" for i in range(6)] + [f"{now - 60}\t1\t/x\tgit status"]
    (data / "commands.tsv").write_text("\n".join(rows) + "\n")
    bindir = home / "bin"
    bindir.mkdir()
    sent = home / "sent"
    stub = bindir / "notify-send"
    stub.write_text(f'#!/bin/sh\nprintf "%s|%s\\n" "$1" "$4" >> {sent}\n')
    stub.chmod(0o755)
    env = dict(os.environ, HOME=d, XDG_DATA_HOME=d + "/.local/share", PATH=f"{bindir}:{os.environ['PATH']}")
    script = str(ROOT / "scripts/habits-digest.sh")
    subprocess.run(["bash", script], env=env)
    assert sent.exists() and "commands in 7 days" in sent.read_text()
    first = sent.read_text()
    subprocess.run(["bash", script], env=env)             # the same week: no second notification
    assert sent.read_text() == first


def test_digest_waits_for_enough_data():
    d = tempfile.mkdtemp()
    home = pathlib.Path(d)
    data = home / ".local/share/habits"
    data.mkdir(parents=True)
    import time
    (data / "commands.tsv").write_text(f"{int(time.time()) - 60}\t0\t/x\tls\n")   # one minute of data
    bindir = home / "bin"
    bindir.mkdir()
    sent = home / "sent"
    stub = bindir / "notify-send"
    stub.write_text(f'#!/bin/sh\necho x >> {sent}\n')
    stub.chmod(0o755)
    env = dict(os.environ, HOME=d, XDG_DATA_HOME=d + "/.local/share", PATH=f"{bindir}:{os.environ['PATH']}")
    subprocess.run(["bash", str(ROOT / "scripts/habits-digest.sh")], env=env)
    assert not sent.exists()
