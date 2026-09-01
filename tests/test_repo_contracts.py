"""Cross-cutting contracts between parts of the repo that drift apart quietly.

These are the failures where each file is individually fine and the *pair* is
wrong: a name promised in one place and defined in another, a diagnostic that
stopped diagnosing. Nothing else looks for them, and they surface weeks later on
a real machine rather than at commit time -- which is how the shell inventory
came to reference three functions that had moved out of the shared modules.
"""

import json
import re
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MODULES = REPO_ROOT / "bashrc/.shell_modules"
INVENTORY = REPO_ROOT / "scripts/shell-inventory.expected"
DOCTOR = REPO_ROOT / "scripts/doctor.sh"
DOCTOR_D = REPO_ROOT / "scripts/doctor.d"

# The dirs gen-shell-inventory.sh sources. bash/ and zsh/ are adapters and are
# deliberately out of the shared floor.
SHARED_DIRS = ("core", "git", "tools")


def shared_module_text():
    """Everything the shared modules bring into a shell.

    lib/os.sh is included because tools/clipboard.sh sources it, so its
    predicates (is_macos, detect_arch, ...) really are part of the shared
    surface even though they live outside .shell_modules.
    """
    out = [(REPO_ROOT / "lib/os.sh").read_text()]
    for d in SHARED_DIRS:
        for f in sorted((MODULES / d).glob("*.sh")):
            out.append(f.read_text())
    return "\n".join(out)


def parse_inventory():
    entries = []
    for line in INVENTORY.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        kind, _, name = line.partition(" ")
        entries.append((kind, name.strip()))
    return entries


def test_inventory_is_not_empty():
    assert len(parse_inventory()) > 50


def test_every_inventory_name_is_declared_in_a_shared_module():
    """The floor must only promise names the shared modules actually define.

    A name that moved to bash/ or zsh/ still exists in the repo, so grepping
    everything would not notice. The floor is specifically about what BOTH
    shells get, so only core/, git/ and tools/ count.
    """
    text = shared_module_text()
    missing = []
    for kind, name in parse_inventory():
        escaped = re.escape(name)
        # The recorded kind describes how the name appears at runtime, not how
        # it is written: wfn registers a function and it shows up as an alias.
        # So any declaration form counts.
        found = (
            re.search(rf"^\s*alias\s+{escaped}=", text, re.M)
            or re.search(rf"^\s*(function\s+)?{escaped}\s*\(\s*\)", text, re.M)
            or re.search(rf"^\s*function\s+{escaped}\b", text, re.M)
            or re.search(rf"^\s*wfn\s+{escaped}\b", text, re.M)
        )
        if not found:
            missing.append(f"{kind} {name}")
    assert not missing, (
        "shell-inventory.expected promises names no shared module defines "
        "(moved to bash/ or zsh/, or deleted): "
        + ", ".join(missing)
        + "\nRegenerate with scripts/gen-shell-inventory.sh, or fix the module."
    )


def run_doctor(*args):
    return subprocess.run(
        [str(DOCTOR), *args],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
        timeout=180,
    )


def test_doctor_emits_valid_json():
    """--json is the form meant to be handed to an agent; it has to parse."""
    res = run_doctor("--json")
    # doctor exits non-zero when checks fail, which is normal off a real machine.
    data = json.loads(res.stdout)
    assert "checks" in data and "summary" in data
    assert data["checks"], "doctor produced no checks at all"


def test_every_doctor_module_reports_something():
    """A check that errors before reporting leaves a silent hole in doctor.

    doctor.sh derives each module's section from its filename (10-symlinks.sh ->
    symlinks), so a section missing from the output means that file contributed
    nothing -- which for a diagnostic tool is indistinguishable from healthy.
    """
    data = json.loads(run_doctor("--json").stdout)
    reported = {c.get("section") for c in data["checks"]}
    expected = {
        f.name.split("-", 1)[1].removesuffix(".sh") for f in DOCTOR_D.glob("*.sh")
    }
    silent = sorted(expected - reported)
    assert not silent, f"doctor.d modules that reported nothing: {silent}"


def test_doctor_only_filter_works():
    """--only is how you re-check one thing after fixing it."""
    data = json.loads(run_doctor("--json", "--only", "usage").stdout)
    sections = {c.get("section") for c in data["checks"]}
    assert sections == {"usage"}, sections
