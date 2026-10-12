"""backup.sh against a throwaway local restic repo and a fake HOME: nothing real is touched.
Skipped when restic is not installed."""
import os
import pathlib
import shutil
import subprocess
import tempfile

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = str(ROOT / "scripts/backup.sh")


@pytest.mark.skipif(shutil.which("restic") is None, reason="restic not installed")
def test_backup_restore_roundtrip_and_excludes():
    d = pathlib.Path(tempfile.mkdtemp())
    home = d / "home"
    for p in ("work", ".cache", ".local/share/Steam", "Downloads", "proj/target", ".config/dots"):
        (home / p).mkdir(parents=True)
    (home / "work/notes.txt").write_text("important")
    (home / ".cache/c.bin").write_text("junk")
    (home / ".local/share/Steam/g").write_text("game")
    (home / "Downloads/d.iso").write_text("dl")
    (home / "proj/target/o.o").write_text("obj")
    (home / ".config/dots/restic-password").write_text("pw-for-test\n")
    (home / ".config/dots/backup.conf").write_text(
        f"RESTIC_REPOSITORY={d}/repo\nRESTIC_PASSWORD_FILE={home}/.config/dots/restic-password\n")
    env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"), XDG_STATE_HOME=str(home / ".state"))
    subprocess.run(["restic", "-r", f"{d}/repo", "--password-file", f"{home}/.config/dots/restic-password", "init"],
                   env=env, check=True, capture_output=True)
    subprocess.run(["bash", SCRIPT], env=env, check=True, capture_output=True)
    subprocess.run(["bash", SCRIPT, "restore", "latest", str(d / "out")], env=env, check=True, capture_output=True)
    out = d / "out" / str(home).lstrip("/")
    assert (out / "work/notes.txt").read_text() == "important"
    for excluded in (".cache/c.bin", ".local/share/Steam/g", "Downloads/d.iso", "proj/target/o.o",
                     ".config/dots/restic-password"):
        assert not (out / excluded).exists(), excluded
    assert (home / ".state/dots/last-backup").exists()
