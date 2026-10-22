import os
from pathlib import Path

import pytest

import symlink

REPO_ROOT = Path(symlink.__file__).resolve().parent

# Config entries that only make sense on a Wayland/Linux box (M03's
# DARWIN_CONFIG_EXCLUDE). Kept here as the independent expectation the
# darwin/linux tests check against, not a re-import of the value under test.
WAYLAND_ONLY_CONFIG = {"hypr", "waybar", "mako", "mimeapps.list"}

# The reverse: config entries that only make sense on darwin (M03's
# LINUX_CONFIG_EXCLUDE).
DARWIN_ONLY_CONFIG = {"ghostty"}

COMMON_TOP_LEVEL = {
    Path(".bashrc"): REPO_ROOT / "bashrc" / ".bashrc",
    Path(".bash_profile"): REPO_ROOT / "bashrc" / ".bash_profile",
    Path(".gitconfig"): REPO_ROOT / "bashrc" / ".gitconfig",
    Path(".profile"): REPO_ROOT / "bashrc" / ".profile",
    Path(".ripgreprc"): REPO_ROOT / "bashrc" / ".ripgreprc",
    Path(".shell_modules"): REPO_ROOT / "bashrc" / ".shell_modules",
}

# clangd is deliberately absent from here: on Linux it's symlinked like any
# other common config entry (added in expected_links() below), but on
# darwin it's excluded from symlink.py entirely (M27) -- macos/embedded.sh
# generates ~/.config/clangd/config.yaml itself once a toolchain is
# installed, since the include paths depend on the xpm-picked version.
COMMON_CONFIG_ENTRIES = {
    Path(".config/fd"): REPO_ROOT / "bashrc" / ".config" / "fd",
    Path(".config/gh"): REPO_ROOT / "bashrc" / ".config" / "gh",
    Path(".config/git"): REPO_ROOT / "bashrc" / ".config" / "git",
    Path(".config/mise"): REPO_ROOT / "bashrc" / ".config" / "mise",
    Path(".config/zed"): REPO_ROOT / "bashrc" / ".config" / "zed",
    Path(".config/zellij"): REPO_ROOT / "bashrc" / ".config" / "zellij",
    # Linked twice by main(): first by the bashrc/.config loop (pointing at
    # the tracked bashrc/.config/starship.toml symlink), then overwritten by
    # the explicit starship block later in main() so it ends up pointing at
    # the real top-level starship.toml. The second write wins.
    Path(".config/starship.toml"): REPO_ROOT / "starship.toml",
    Path(".ssh/config"): REPO_ROOT / "bashrc" / ".ssh" / "config",
}

# config.darwin (M30) carries the one ssh_config keyword (UseKeychain) that
# only Apple's OpenSSH fork understands -- linked in on darwin only, same as
# DARWIN_ONLY_CONFIG_TARGETS below but under .ssh/ rather than .config/.
DARWIN_ONLY_SSH_TARGETS = {
    Path(".ssh/config.darwin"): REPO_ROOT / "bashrc" / ".ssh" / "config.darwin",
}

# The zsh entrypoint (M08) -- darwin only, same reasoning as the ssh target
# above: Linux/WSL keep bash as the login shell.
DARWIN_ONLY_TOP_LEVEL_TARGETS = {
    Path(".zshrc"): REPO_ROOT / "bashrc" / ".zshrc",
}

WAYLAND_ONLY_CONFIG_TARGETS = {
    Path(".config/hypr"): REPO_ROOT / "bashrc" / ".config" / "hypr",
    Path(".config/waybar"): REPO_ROOT / "bashrc" / ".config" / "waybar",
    Path(".config/mako"): REPO_ROOT / "bashrc" / ".config" / "mako",
    Path(".config/mimeapps.list"): REPO_ROOT / "bashrc" / ".config" / "mimeapps.list",
}

DARWIN_ONLY_CONFIG_TARGETS = {
    Path(".config/ghostty"): REPO_ROOT / "bashrc" / ".config" / "ghostty",
}

NVIM_ENTRIES = {
    Path(".config/nvim/init.lua"): REPO_ROOT / "nvim" / "init.lua",
    Path(".config/nvim/lsp"): REPO_ROOT / "nvim" / "lsp",
    Path(".config/nvim/colors"): REPO_ROOT / "nvim" / "colors",
    Path(".config/nvim/lua"): REPO_ROOT / "nvim" / "lua",
    Path(".config/nvim/stylua.toml"): REPO_ROOT / "nvim" / "stylua.toml",
    Path(".config/nvim/testfiles"): REPO_ROOT / "nvim" / "testfiles",
}

CAVEMAN_ENTRIES = {
    Path(".cursor/rules/caveman.mdc"): REPO_ROOT / "caveman" / "caveman.mdc",
    Path(".claude/CLAUDE.md"): REPO_ROOT / "caveman" / "CLAUDE.md",
    Path(".claude/skills/my-review"): REPO_ROOT / "claude" / "skills" / "my-review",
}


def expected_links(darwin):
    expected = dict(COMMON_TOP_LEVEL)
    expected.update(COMMON_CONFIG_ENTRIES)
    if darwin:
        expected.update(DARWIN_ONLY_CONFIG_TARGETS)
        expected.update(DARWIN_ONLY_SSH_TARGETS)
        expected.update(DARWIN_ONLY_TOP_LEVEL_TARGETS)
    else:
        expected.update(WAYLAND_ONLY_CONFIG_TARGETS)
        expected[Path(".config/clangd")] = REPO_ROOT / "bashrc" / ".config" / "clangd"
    expected.update(NVIM_ENTRIES)
    expected.update(CAVEMAN_ENTRIES)
    skip = (
        {"sway", "waybar", "which-key", "fuzzel", "swaylock", "gtklock"}
        if darwin
        else {"aerospace", "hammerspoon"}
    )
    for entry in (REPO_ROOT / "parts").glob("*/.config/*"):
        if entry.parts[-3] not in skip:
            expected[Path(".config") / entry.name] = entry
    if darwin:
        expected[Path(".hammerspoon")] = (
            REPO_ROOT / "parts" / "hammerspoon" / ".hammerspoon"
        )
    return expected


@pytest.fixture(autouse=True)
def all_tools_installed(monkeypatch):
    """The link-set tests assert the full set; presence filtering has its own tests below."""
    monkeypatch.setattr(symlink, "tool_present", lambda spec: True)


def run_symlink_main(monkeypatch, home, system):
    monkeypatch.setenv("HOME", str(home))
    monkeypatch.setattr(symlink.platform, "system", lambda: system)
    monkeypatch.setattr("sys.argv", ["symlink.py", "-y"])
    symlink.main()


def links_under(root):
    """Map of path-relative-to-root -> resolved target, for every symlink under root."""
    found = {}
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        for name in list(dirnames) + filenames:
            candidate = Path(dirpath) / name
            if candidate.is_symlink():
                found[candidate.relative_to(root)] = candidate.resolve()
    return found


@pytest.fixture
def fake_home(tmp_path):
    home = tmp_path / "home"
    home.mkdir()
    return home


@pytest.mark.parametrize("system,darwin", [("Linux", False), ("Darwin", True)])
def test_link_set_matches_expected(monkeypatch, fake_home, system, darwin):
    run_symlink_main(monkeypatch, fake_home, system)
    actual = links_under(fake_home)
    expected = expected_links(darwin)
    # git-ignored files (local scripts like bashrc/auth.sh) are linked too, but they exist on one machine only: not part of the contract
    ignored = {
        REPO_ROOT / f
        for f in subprocess.run(
            [
                "git",
                "-C",
                str(REPO_ROOT),
                "ls-files",
                "-o",
                "-i",
                "--exclude-standard",
                "-z",
            ],
            capture_output=True,
            text=True,
        ).stdout.split("\0")
        if f
    }
    actual = {rel: target for rel, target in actual.items() if target not in ignored}

    assert set(actual) == set(expected), (
        f"link set mismatch for {system}: "
        f"missing={set(expected) - set(actual)} "
        f"unexpected={set(actual) - set(expected)}"
    )
    for rel, target in expected.items():
        assert (
            actual[rel] == target.resolve()
        ), f"{rel} -> {actual[rel]}, expected {target.resolve()}"


def test_darwin_excludes_wayland_only_configs(monkeypatch, fake_home):
    run_symlink_main(monkeypatch, fake_home, "Darwin")
    for name in WAYLAND_ONLY_CONFIG:
        entry = fake_home / ".config" / name
        assert not entry.is_symlink()
        assert not entry.exists()


def test_linux_includes_wayland_only_configs(monkeypatch, fake_home):
    run_symlink_main(monkeypatch, fake_home, "Linux")
    for name in WAYLAND_ONLY_CONFIG:
        assert (fake_home / ".config" / name).is_symlink()


def test_linux_excludes_darwin_only_configs(monkeypatch, fake_home):
    run_symlink_main(monkeypatch, fake_home, "Linux")
    for name in DARWIN_ONLY_CONFIG:
        entry = fake_home / ".config" / name
        assert not entry.is_symlink()
        assert not entry.exists()


def test_darwin_includes_darwin_only_configs(monkeypatch, fake_home):
    run_symlink_main(monkeypatch, fake_home, "Darwin")
    for name in DARWIN_ONLY_CONFIG:
        assert (fake_home / ".config" / name).is_symlink()


def test_darwin_excludes_clangd(monkeypatch, fake_home):
    # M27: the tracked clangd/ directory holds both the static Linux config
    # and the darwin template -- neither is what macos/embedded.sh wants
    # symlinked wholesale, since it generates config.yaml itself once a
    # toolchain is actually installed.
    run_symlink_main(monkeypatch, fake_home, "Darwin")
    entry = fake_home / ".config" / "clangd"
    assert not entry.is_symlink()
    assert not entry.exists()


def test_linux_includes_clangd(monkeypatch, fake_home):
    run_symlink_main(monkeypatch, fake_home, "Linux")
    assert (fake_home / ".config" / "clangd").is_symlink()


def test_config_dir_is_real_not_symlinked(monkeypatch, fake_home):
    # The single safety property symlink.py is built around: ~/.config must
    # stay a real directory, never a symlink into the repo, or every app that
    # writes into $XDG_CONFIG_HOME would write straight into git.
    run_symlink_main(monkeypatch, fake_home, "Linux")
    config_dir = fake_home / ".config"
    assert config_dir.is_dir()
    assert not config_dir.is_symlink()


@pytest.mark.parametrize("system", ["Linux", "Darwin"])
def test_ssh_dir_is_real_not_symlinked(monkeypatch, fake_home, system):
    # Same safety property as .config above, for the same reason: ~/.ssh
    # holds real private keys and known_hosts, which must never end up
    # inside the git repo (M30).
    run_symlink_main(monkeypatch, fake_home, system)
    ssh_dir = fake_home / ".ssh"
    assert ssh_dir.is_dir()
    assert not ssh_dir.is_symlink()
    assert (ssh_dir.stat().st_mode & 0o777) == 0o700


def test_linux_excludes_darwin_ssh_config(monkeypatch, fake_home):
    run_symlink_main(monkeypatch, fake_home, "Linux")
    entry = fake_home / ".ssh" / "config.darwin"
    assert not entry.is_symlink()
    assert not entry.exists()


def test_darwin_includes_darwin_ssh_config(monkeypatch, fake_home):
    run_symlink_main(monkeypatch, fake_home, "Darwin")
    assert (fake_home / ".ssh" / "config.darwin").is_symlink()


def test_linux_excludes_zshrc(monkeypatch, fake_home):
    run_symlink_main(monkeypatch, fake_home, "Linux")
    entry = fake_home / ".zshrc"
    assert not entry.is_symlink()
    assert not entry.exists()


def test_darwin_includes_zshrc(monkeypatch, fake_home):
    run_symlink_main(monkeypatch, fake_home, "Darwin")
    assert (fake_home / ".zshrc").is_symlink()


@pytest.mark.parametrize("system", ["Linux", "Darwin"])
def test_every_link_resolves_into_repo(monkeypatch, fake_home, system):
    run_symlink_main(monkeypatch, fake_home, system)
    links = links_under(fake_home)
    assert links, "expected at least one symlink to be created"
    for rel, target in links.items():
        assert (
            target == REPO_ROOT or REPO_ROOT in target.parents
        ), f"{rel} resolves outside the repo: {target}"


def test_existing_real_file_is_backed_up(monkeypatch, fake_home):
    bashrc_path = fake_home / ".bashrc"
    bashrc_path.write_text("pre-existing real file, not a symlink\n")

    run_symlink_main(monkeypatch, fake_home, "Linux")

    backups = sorted(fake_home.glob(".bashrc.bak-*"))
    assert len(backups) == 1, f"expected exactly one backup, found {backups}"
    assert backups[0].read_text() == "pre-existing real file, not a symlink\n"

    assert bashrc_path.is_symlink()
    assert bashrc_path.resolve() == (REPO_ROOT / "bashrc" / ".bashrc").resolve()


def test_existing_symlink_is_replaced_without_backup(monkeypatch, fake_home):
    decoy_target = fake_home / "elsewhere"
    decoy_target.write_text("not the real .ripgreprc\n")
    (fake_home / ".ripgreprc").symlink_to(decoy_target)

    run_symlink_main(monkeypatch, fake_home, "Linux")

    assert not list(fake_home.glob(".ripgreprc.bak-*"))
    ripgreprc_link = fake_home / ".ripgreprc"
    assert ripgreprc_link.is_symlink()
    assert ripgreprc_link.resolve() == (REPO_ROOT / "bashrc" / ".ripgreprc").resolve()


def test_part_link_unlink_swap(tmp_path):
    a = tmp_path / "parts" / "a"
    b = tmp_path / "parts" / "b"
    (a / ".config" / "app").mkdir(parents=True)
    (b / ".config" / "app").mkdir(parents=True)
    (a / ".rc").write_text("a")
    home = tmp_path / "home"
    home.mkdir()
    other = tmp_path / "keep"
    other.write_text("x")
    (home / ".config").mkdir()
    (home / ".config" / "other").symlink_to(other)

    symlink.link_part(a, home)
    assert (home / ".config" / "app").resolve() == (a / ".config" / "app").resolve()
    assert (home / ".rc").is_symlink()

    symlink.unlink_part(a, home)
    assert not (home / ".config" / "app").exists() and not (home / ".rc").exists()
    assert (home / ".config" / "other").is_symlink()  # untouched

    symlink.link_part(a, home)
    symlink.unlink_part(a, home)
    symlink.link_part(b, home)  # swap
    assert (home / ".config" / "app").resolve() == (b / ".config" / "app").resolve()


def test_parts_and_configs_for_missing_tools_are_skipped(monkeypatch, fake_home):
    monkeypatch.setattr(symlink, "tool_present", lambda spec: False)
    run_symlink_main(monkeypatch, fake_home, "Linux")
    assert not (fake_home / ".config" / "sway").exists()
    assert not (fake_home / ".config" / "waybar").exists()
    assert not (fake_home / ".config" / "zellij").exists()
    # data-only parts and always-on entries are still linked
    assert (fake_home / ".config" / "palette").is_symlink()
    assert (fake_home / ".bashrc").is_symlink()


def test_installed_tool_gets_its_part(monkeypatch, fake_home):
    monkeypatch.setattr(symlink, "tool_present", lambda spec: spec == "sway")
    run_symlink_main(monkeypatch, fake_home, "Linux")
    assert (fake_home / ".config" / "sway").is_symlink()
    assert not (fake_home / ".config" / "waybar").exists()


# --- an older installer linked ~/.config wholesale into the repo; running this one on such a machine must not loop ---


def test_a_link_that_would_point_at_itself_is_skipped_not_looped(tmp_path):
    # ~/.config -> repo/.config, so ~/.config/nvim and repo/.config/nvim are the same folder. Moving the "existing" folder aside and
    # linking the name to the repo path would put the repo's own folder in a backup and leave a symlink pointing at itself.
    repo_cfg = tmp_path / "repo" / ".config"
    (repo_cfg / "nvim").mkdir(parents=True)
    (repo_cfg / "nvim" / "init.lua").write_text("keep me\n")
    home = tmp_path / "home"
    home.mkdir()
    (home / ".config").symlink_to(repo_cfg)

    symlink.create_symlink(
        str(repo_cfg / "nvim"), str(home / ".config" / "nvim"), auto_yes=True
    )

    assert (repo_cfg / "nvim").is_dir() and not (repo_cfg / "nvim").is_symlink()
    assert (repo_cfg / "nvim" / "init.lua").read_text() == "keep me\n"
    assert not list(repo_cfg.glob("*.bak-*")), "nothing was moved aside"
    assert (
        home / ".config" / "nvim" / "init.lua"
    ).read_text() == "keep me\n", "and it still reads through ~/.config"


def test_main_warns_when_config_dir_is_a_symlink(
    monkeypatch, fake_home, tmp_path, capsys
):
    elsewhere = tmp_path / "wholesale"
    elsewhere.mkdir()
    (fake_home / ".config").symlink_to(elsewhere)
    run_symlink_main(monkeypatch, fake_home, "Linux")
    out = capsys.readouterr().out
    assert "~/.config is a symlink" in out and "write straight into" in out
    assert (
        list(elsewhere.iterdir()) == []
    ), "nothing was written through the link: not by the config loop, nvim, starship, parts or secrets"


# --- replacing a real ~/.ssh/config must not lose its host entries ---


def test_an_existing_ssh_config_is_kept_as_an_included_file(monkeypatch, fake_home):
    ssh = fake_home / ".ssh"
    ssh.mkdir()
    old = "Host pi\n    HostName 10.0.0.2\n    User pi\n"
    (ssh / "config").write_text(old)

    run_symlink_main(monkeypatch, fake_home, "Linux")

    kept = fake_home / ".local" / "secrets" / "ssh" / "legacy-config.conf"
    assert (
        kept.read_text() == old
    ), "the tracked config Includes ~/.local/secrets/ssh/*.conf, so the old hosts keep working"
    assert (kept.stat().st_mode & 0o777) == 0o600
    assert (ssh / "config").is_symlink()
    assert len(list(ssh.glob("config.bak-*"))) == 1


def test_a_kept_ssh_config_is_not_overwritten_by_a_second_run(monkeypatch, fake_home):
    kept_dir = fake_home / ".local" / "secrets" / "ssh"
    kept_dir.mkdir(parents=True)
    (kept_dir / "legacy-config.conf").write_text("Host mine\n")
    ssh = fake_home / ".ssh"
    ssh.mkdir()
    (ssh / "config").write_text("Host other\n")

    run_symlink_main(monkeypatch, fake_home, "Linux")

    assert (kept_dir / "legacy-config.conf").read_text() == "Host mine\n"


def test_running_twice_leaves_the_same_links_and_makes_no_backups(
    monkeypatch, fake_home
):
    run_symlink_main(monkeypatch, fake_home, "Linux")
    first = links_under(fake_home)
    run_symlink_main(monkeypatch, fake_home, "Linux")
    assert links_under(fake_home) == first
    assert not list(fake_home.rglob("*.bak-*"))


# --- the repair: an older installer linked ~/.config wholesale into the repo; make it a real directory, keep everything ---

import subprocess


def git(repo, *args):
    return subprocess.run(
        ["git", "-c", "user.name=t", "-c", "user.email=t@t", "-C", str(repo), *args],
        check=True,
        capture_output=True,
        text=True,
    ).stdout


@pytest.fixture
def old_machine(tmp_path):
    """A repo whose bashrc/.config has tracked configs, plus what apps and the old installer left in it (untracked), and a home whose
    ~/.config is a symlink to it."""
    repo = tmp_path / "repo"
    cfg = repo / "bashrc" / ".config"
    (cfg / "git").mkdir(parents=True)
    (cfg / "git" / "config").write_text("[user]\n")
    (repo / "starship.toml").write_text("s\n")
    (cfg / "starship.toml").symlink_to("../../starship.toml")
    (repo / ".gitignore").write_text("")
    git(repo, "init", "-q", "-b", "main")
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", "base")
    (cfg / "cursor").mkdir()
    (cfg / "cursor" / "state.json").write_text("app state\n")
    (cfg / "palette").symlink_to(
        repo / "somewhere"
    )  # a link made by part linking, untracked
    (cfg / "git" / "hosts.yml").write_text(
        "token\n"
    )  # untracked file inside a tracked folder: stays with its folder
    home = tmp_path / "home"
    home.mkdir()
    (home / ".config").symlink_to(cfg)
    return repo, home, cfg


def test_repair_makes_config_a_real_directory_and_moves_only_what_git_does_not_track(
    old_machine,
):
    repo, home, cfg = old_machine
    assert git(repo, "status", "--porcelain", "--untracked-files=no") == ""

    assert (
        symlink.repair_wholesale_config(home / ".config", repo, auto_yes=True) is True
    )

    config = home / ".config"
    assert config.is_dir() and not config.is_symlink()
    assert (
        config / "cursor" / "state.json"
    ).read_text() == "app state\n", "app state moved to the real directory"
    assert (config / "palette").is_symlink()
    assert not (cfg / "cursor").exists() and not (cfg / "palette").is_symlink()
    assert (cfg / "git" / "config").exists() and (
        cfg / "git" / "hosts.yml"
    ).read_text() == "token\n", "tracked folders stay in the repo, with what is inside"
    assert not (
        config / "git"
    ).exists(), "the tracked entries are linked by the normal install, not moved"
    assert (
        git(repo, "status", "--porcelain", "--untracked-files=no") == ""
    ), "no tracked file changed"
    assert "cursor" not in git(
        repo, "status", "--porcelain"
    ), "and the repo no longer holds the app state"


def test_repair_twice_changes_nothing_and_says_so(old_machine):
    repo, home, _ = old_machine
    symlink.repair_wholesale_config(home / ".config", repo, auto_yes=True)
    state = sorted(str(p) for p in (home / ".config").rglob("*"))
    assert (
        symlink.repair_wholesale_config(home / ".config", repo, auto_yes=True) is False
    )
    assert sorted(str(p) for p in (home / ".config").rglob("*")) == state


def test_repair_dry_run_and_a_declined_question_change_nothing(
    old_machine, monkeypatch
):
    repo, home, cfg = old_machine
    plan = symlink.repair_wholesale_config(home / ".config", repo, dry_run=True)
    assert plan == ["cursor", "palette"]
    monkeypatch.setattr("builtins.input", lambda *_: "n")
    assert symlink.repair_wholesale_config(home / ".config", repo) is False
    assert (home / ".config").is_symlink() and (cfg / "cursor" / "state.json").exists()


def test_repair_leaves_a_symlink_that_points_elsewhere_and_a_machine_without_git_alone(
    old_machine, tmp_path
):
    repo, home, cfg = old_machine
    other = tmp_path / "other"
    other.mkdir()
    (home / ".config").unlink()
    (home / ".config").symlink_to(other)
    assert (
        symlink.repair_wholesale_config(home / ".config", repo, auto_yes=True) is False
    )
    assert (home / ".config").is_symlink()
    (home / ".config").unlink()
    (home / ".config").symlink_to(cfg)
    not_git = tmp_path / "plain"
    (not_git / "bashrc" / ".config").mkdir(parents=True)
    (home / ".config").unlink()
    (home / ".config").symlink_to(not_git / "bashrc" / ".config")
    assert (
        symlink.repair_wholesale_config(home / ".config", not_git, auto_yes=True)
        is False
    )
    assert (
        home / ".config"
    ).is_symlink(), "without git there is no telling what is tracked: nothing is moved"


@pytest.mark.parametrize("system", ["Linux", "Darwin"])
def test_a_whole_install_on_an_old_machine_repairs_it_and_links_the_tracked_configs(
    monkeypatch, old_machine, system
):
    repo, home, cfg = old_machine
    (repo / "bashrc" / ".bashrc").write_text("b\n")
    (repo / "bashrc" / ".ssh").mkdir()
    (repo / "bashrc" / ".ssh" / "config").write_text("Host *\n")
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", "more")
    monkeypatch.setattr(symlink, "__file__", str(repo / "symlink.py"))

    run_symlink_main(monkeypatch, home, system)

    config = home / ".config"
    assert config.is_dir() and not config.is_symlink()
    assert (config / "git").is_symlink() and (config / "git").resolve() == (
        cfg / "git"
    ).resolve()
    assert (config / "cursor" / "state.json").exists()
    assert (config / "starship.toml").resolve() == (repo / "starship.toml").resolve()
    assert (
        git(repo, "status", "--porcelain", "--untracked-files=no") == ""
    ), "the install changed no tracked file of the repo"
    assert not list(repo.rglob("*.bak-*")), "and moved no folder of the repo aside"
