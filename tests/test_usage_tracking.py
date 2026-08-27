"""Tests for the shortcut usage tracking and the report built on it.

The privacy property is the important one here: the logger must record command
names and never arguments. A shell history quietly duplicated into a second
file would be a liability, and the failure would be silent.
"""

import os
import shutil
import subprocess
import time
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
LOGGER = REPO_ROOT / "bashrc/.shell_modules/core/usage_tracking.sh"
REPORT = REPO_ROOT / "scripts/usage-report.sh"

SHELLS = [s for s in ("bash", "zsh") if shutil.which(s)]


def run_logger(shell, log_path, commands):
    """Source the logger in `shell` and record each command, return the log."""
    lines = [
        f'export DOTFILES_USAGE_LOG="{log_path}"',
        f'. "{LOGGER}"',
    ]
    lines += [f"__usage_record {c!r}" for c in commands]
    subprocess.run(
        [shell, "-c", "\n".join(lines)],
        check=True,
        capture_output=True,
        cwd=REPO_ROOT,
    )
    return log_path.read_text() if log_path.exists() else ""


@pytest.mark.parametrize("shell", SHELLS)
def test_logger_parses_and_records(shell, tmp_path):
    log = tmp_path / "usage.tsv"
    out = run_logger(shell, log, ["gs", "ll", "mkcd"])
    recorded = [line.split("\t")[2] for line in out.strip().splitlines()]
    assert recorded == ["gs", "ll", "mkcd"]


@pytest.mark.parametrize("shell", SHELLS)
def test_logger_never_records_arguments(shell, tmp_path):
    """The whole point: names in, arguments never."""
    log = tmp_path / "usage.tsv"
    secrets = [
        "logch TIME-195-confidential",
        "ssh-add /home/someone/.ssh/id_ed25519_prod",
        "curl -H 'Authorization: Bearer sk-abc123'",
        "export GITLAB_ACCESS_KEY=glpat-secret",
    ]
    out = run_logger(shell, log, secrets)
    for leak in (
        "confidential",
        "id_ed25519_prod",
        "sk-abc123",
        "glpat-secret",
        "/home/someone",
        "Authorization",
    ):
        assert leak not in out, f"{leak!r} leaked into the usage log"


@pytest.mark.parametrize("shell", SHELLS)
def test_logger_skips_paths_and_assignments(shell, tmp_path):
    """Bare paths and env-var prefixes are not shortcuts, so they are noise."""
    log = tmp_path / "usage.tsv"
    out = run_logger(
        shell, log, ["./bootstrap.sh", "/usr/bin/env", "FOO=bar", "# a comment"]
    )
    assert out.strip() == ""


@pytest.mark.parametrize("shell", SHELLS)
def test_logger_trims_leading_whitespace(shell, tmp_path):
    log = tmp_path / "usage.tsv"
    out = run_logger(shell, log, ["    gs   --porcelain"])
    assert out.split("\t")[2].strip() == "gs"


def test_logger_is_inert_when_disabled(tmp_path):
    log = tmp_path / "usage.tsv"
    subprocess.run(
        [
            "bash",
            "-c",
            f'export DOTFILES_USAGE_TRACK=0 DOTFILES_USAGE_LOG="{log}"\n'
            f'. "{LOGGER}"\n'
            "type __usage_record >/dev/null 2>&1 && exit 1\nexit 0",
        ],
        check=True,
        capture_output=True,
        cwd=REPO_ROOT,
    )
    assert not log.exists()


def write_log(path, rows):
    """rows: (age_days, command) -- oldest first."""
    now = int(time.time())
    path.write_text(
        "".join(f"{now - int(age * 86400)}\tbash\t{cmd}\n" for age, cmd in rows)
    )


def report(log, *args):
    env = dict(os.environ, DOTFILES_USAGE_LOG=str(log))
    return subprocess.run(
        [str(REPORT), *args],
        check=True,
        capture_output=True,
        text=True,
        env=env,
        cwd=REPO_ROOT,
    ).stdout


def test_report_handles_a_missing_log(tmp_path):
    out = report(tmp_path / "nope.tsv")
    assert "No usage log" in out
    assert "check back in a month" in out


def test_report_separates_used_from_unused(tmp_path):
    log = tmp_path / "usage.tsv"
    # `a` is a real git alias in this repo; `git` is not one of ours.
    write_log(log, [(40, "a"), (20, "a"), (1, "git")])
    out = report(log, "--all")
    assert "USED (1)" in out
    assert "NEVER USED" in out
    # A command we do not declare must not be reported as one of ours.
    assert "\n       2  git " not in out


def test_report_counts_each_name_once(tmp_path):
    """ll is declared twice (eza vs ls branch); it is still one shortcut."""
    log = tmp_path / "usage.tsv"
    write_log(log, [(40, "ll"), (1, "ll")])
    out = report(log, "--used")
    assert out.count("\n") > 0
    assert "(+1 more)" in out
    assert len([ln for ln in out.splitlines() if ln.strip().endswith("more)")]) == 1


def test_report_warns_when_the_window_is_too_short(tmp_path):
    log = tmp_path / "usage.tsv"
    write_log(log, [(2, "a")])
    assert "Too early to delete anything" in report(log)
    write_log(log, [(60, "a")])
    assert "Too early to delete anything" not in report(log)


def test_report_json_is_parseable(tmp_path):
    import json

    log = tmp_path / "usage.tsv"
    write_log(log, [(40, "a"), (1, "a")])
    data = json.loads(report(log, "--json"))
    assert data["exists"] is True
    assert data["declared"] > 100
    assert data["used"] == 1
    assert data["unused"] == data["declared"] - 1
    assert "a" not in data["unused_names"]


def test_dead_files_mode_runs(tmp_path):
    out = report(tmp_path / "nope.tsv", "--dead-files")
    assert "references" in out


def test_hook_survives_starship_taking_over_prompt_command(tmp_path):
    """starship initialises after core/ and reassigns PROMPT_COMMAND.

    It preserves whatever was there into $STARSHIP_PROMPT_COMMAND and evals that
    inside starship_precmd, so the hook still fires -- but if that ever changes,
    tracking would silently stop collecting and nothing else would notice.
    This reproduces starship's own init.bash logic.
    """
    log = tmp_path / "usage.tsv"
    script = f"""
export DOTFILES_USAGE_LOG="{log}"
. "{LOGGER}"
if [[ -z "${{PROMPT_COMMAND-}}" ]]; then
    PROMPT_COMMAND="starship_precmd"
elif [[ "$PROMPT_COMMAND" != *"starship_precmd"* ]]; then
    STARSHIP_PROMPT_COMMAND="$PROMPT_COMMAND"
    PROMPT_COMMAND="starship_precmd"
fi
starship_precmd() {{ [[ -n "${{STARSHIP_PROMPT_COMMAND-}}" ]] && eval "$STARSHIP_PROMPT_COMMAND"; }}
set -o history
history -s "gs"; starship_precmd
"""
    subprocess.run(
        ["bash", "-c", script], check=True, capture_output=True, cwd=REPO_ROOT
    )
    assert log.exists(), "usage hook was lost when starship took over PROMPT_COMMAND"
    assert log.read_text().strip().split("\t")[2] == "gs"
