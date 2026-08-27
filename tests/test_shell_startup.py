"""Behavioural tests for the shell entrypoints.

check.sh already runs `bash -n` / `zsh -n`, but syntax is not the failure mode
that bites: a file that parses fine can still error while sourcing, mangle PATH,
or -- the one this repo is structurally exposed to -- give bash and zsh a
different set of shortcuts because something was added to one entrypoint and not
the other.

Each test starts a real interactive shell against a staged HOME, so the rc files
run the way they do on a live machine.
"""

import os
import shutil
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
BASHRC = REPO_ROOT / "bashrc/.bashrc"
ZSHRC = REPO_ROOT / "bashrc/.zshrc"
MODULES = REPO_ROOT / "bashrc/.shell_modules"

SHELLS = [s for s in ("bash", "zsh") if shutil.which(s)]
RC = {"bash": BASHRC, "zsh": ZSHRC}


@pytest.fixture
def staged_home(tmp_path):
    """A HOME with ~/.shell_modules linked, as symlink.py would leave it."""
    home = tmp_path / "home"
    home.mkdir()
    (home / ".shell_modules").symlink_to(MODULES)
    (home / ".local" / "state" / "dotfiles").mkdir(parents=True)
    return home


def shell_probe(shell, home, probe):
    """Source the rc in an interactive shell, then run `probe`, return stdout."""
    env = dict(
        os.environ,
        HOME=str(home),
        DOTFILES=str(REPO_ROOT),
        # zellij would take over the session and never return; .bashrc skips it
        # when already inside one.
        ZELLIJ="1",
        DOTFILES_USAGE_LOG=str(home / "usage.tsv"),
    )
    script = f'source "{RC[shell]}" 2>/dev/null\n{probe}'
    return subprocess.run(
        [shell, "-i", "-c", script],
        capture_output=True,
        text=True,
        env=env,
        cwd=REPO_ROOT,
        timeout=60,
    )


@pytest.mark.parametrize("shell", SHELLS)
def test_rc_sources_without_error(shell, staged_home):
    res = shell_probe(shell, staged_home, 'echo "STARTUP_OK"')
    assert "STARTUP_OK" in res.stdout, res.stderr
    assert res.returncode == 0


@pytest.mark.parametrize("shell", SHELLS)
def test_rc_reports_no_errors_on_stderr(shell, staged_home):
    """A module that fails to source is invisible unless something looks."""
    env = dict(
        os.environ,
        HOME=str(staged_home),
        DOTFILES=str(REPO_ROOT),
        ZELLIJ="1",
        DOTFILES_USAGE_LOG=str(staged_home / "usage.tsv"),
    )
    res = subprocess.run(
        [shell, "-i", "-c", f'source "{RC[shell]}"'],
        capture_output=True,
        text=True,
        env=env,
        cwd=REPO_ROOT,
        timeout=60,
    )
    # Running interactively without a tty makes the shell complain about job
    # control. That is an artifact of the test harness, not of the rc files;
    # everything else on stderr is a module that failed to load.
    tty_noise = ("job control", "terminal process group", "Inappropriate ioctl")
    noise = [
        ln
        for ln in res.stderr.splitlines()
        if ln.strip() and not any(n in ln for n in tty_noise)
    ]
    assert not noise, f"{shell} startup wrote to stderr:\n" + "\n".join(noise)


@pytest.mark.parametrize("shell", SHELLS)
def test_dotfiles_is_exported(shell, staged_home):
    res = shell_probe(shell, staged_home, 'echo "D=$DOTFILES"')
    assert "D=" in res.stdout
    assert res.stdout.strip().split("D=")[1] != ""


@pytest.mark.parametrize("shell", SHELLS)
def test_path_has_no_duplicate_entries(shell, staged_home):
    """Duplicate PATH entries mean two mechanisms both claim to own a dir.

    That is how $HOME/.cargo/bin ended up in twice: exported by hand and again
    by .cargo/env.
    """
    res = shell_probe(shell, staged_home, 'printf "%s" "$PATH"')
    entries = [e for e in res.stdout.strip().split(":") if e]
    dupes = {e for e in entries if entries.count(e) > 1}
    assert not dupes, f"{shell} PATH contains duplicates: {sorted(dupes)}"


@pytest.mark.parametrize("shell", SHELLS)
def test_core_surface_loads(shell, staged_home):
    """The core/ modules actually took effect, not just parsed."""
    res = shell_probe(
        shell,
        staged_home,
        "command -v wfn >/dev/null && echo HAS_WFN;"
        " command -v clip >/dev/null && echo HAS_CLIP;"
        " alias vim >/dev/null 2>&1 && echo HAS_VIM",
    )
    for marker in ("HAS_WFN", "HAS_CLIP", "HAS_VIM"):
        assert marker in res.stdout, f"{marker} missing in {shell}: {res.stdout!r}"


@pytest.mark.parametrize("shell", SHELLS)
def test_usage_tracking_is_wired(shell, staged_home):
    res = shell_probe(
        shell, staged_home, "command -v __usage_record >/dev/null && echo TRACKING"
    )
    assert "TRACKING" in res.stdout


@pytest.mark.skipif(len(SHELLS) < 2, reason="needs both bash and zsh")
def test_both_shells_agree_on_shared_shortcuts(staged_home, tmp_path):
    """The drift this repo's core/ + adapter split exists to prevent.

    A shortcut added to one entrypoint and not the other is silent: it simply
    does not exist on the other machine. Shell-specific surface is legitimate,
    so only shortcuts defined under core/ and git/ -- the shared modules -- are
    required to match.
    """
    shared_names = set()
    for module in list((MODULES / "core").glob("*.sh")) + list(
        (MODULES / "git").glob("*.sh")
    ):
        for line in module.read_text().splitlines():
            line = line.strip()
            if line.startswith("alias ") and "=" in line:
                name = line[len("alias ") :].split("=", 1)[0]
                # wfn builds `alias "$fn_name"=...` at runtime; the literal
                # text is not a shortcut name.
                if name.startswith(("$", '"', "'")):
                    continue
                shared_names.add(name)

    assert shared_names, "no shared aliases found -- the parser is wrong"

    seen = {}
    for shell in SHELLS:
        home = tmp_path / f"home-{shell}"
        home.mkdir()
        (home / ".shell_modules").symlink_to(MODULES)
        res = shell_probe(shell, home, "alias")
        seen[shell] = {
            ln.split("=", 1)[0].replace("alias ", "").strip().strip("'\"")
            for ln in res.stdout.splitlines()
            if "=" in ln
        }

    missing = {s: sorted(shared_names - names) for s, names in seen.items()}
    assert not any(missing.values()), (
        "shared shortcuts missing from a shell (bash/zsh drift): "
        f"{ {s: m for s, m in missing.items() if m} }"
    )


def test_entrypoints_do_not_declare_shared_aliases():
    """Architecture rule, from the repo README.

    core/ is the shared surface; the entrypoints wire things up. An alias in
    .bashrc has to be copy-pasted into .zshrc to reach macOS, and the copy is
    what drifts -- which is exactly how `cheat` and `help` ended up defined
    twice. Shell-specific aliases belong in bash/ or zsh/, not here.
    """
    offenders = {}
    for rc in (BASHRC, ZSHRC):
        found = [
            ln.strip()
            for ln in rc.read_text().splitlines()
            if ln.strip().startswith("alias ")
        ]
        if found:
            offenders[rc.name] = found
    assert not offenders, (
        "aliases declared in an entrypoint instead of core/ (or bash/, zsh/ "
        f"if shell-specific): {offenders}"
    )
