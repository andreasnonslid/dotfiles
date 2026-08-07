import os
from pathlib import Path

import pytest

import symlink

REPO_ROOT = Path(symlink.__file__).resolve().parent

# Config entries that only make sense on a Wayland/Linux box (M03's
# DARWIN_CONFIG_EXCLUDE). Kept here as the independent expectation the
# darwin/linux tests check against, not a re-import of the value under test.
WAYLAND_ONLY_CONFIG = {"hypr", "waybar", "mako", "mimeapps.list"}

COMMON_TOP_LEVEL = {
    Path(".bashrc"): REPO_ROOT / "bashrc" / ".bashrc",
    Path(".profile"): REPO_ROOT / "bashrc" / ".profile",
    Path(".ripgreprc"): REPO_ROOT / "bashrc" / ".ripgreprc",
    Path(".shell_modules"): REPO_ROOT / "bashrc" / ".shell_modules",
    Path("z.sh"): REPO_ROOT / "bashrc" / "z.sh",
}

COMMON_CONFIG_ENTRIES = {
    Path(".config/clangd"): REPO_ROOT / "bashrc" / ".config" / "clangd",
    Path(".config/fd"): REPO_ROOT / "bashrc" / ".config" / "fd",
    Path(".config/gh"): REPO_ROOT / "bashrc" / ".config" / "gh",
    Path(".config/git"): REPO_ROOT / "bashrc" / ".config" / "git",
    Path(".config/zellij"): REPO_ROOT / "bashrc" / ".config" / "zellij",
    # Linked twice by main(): first by the bashrc/.config loop (pointing at
    # the tracked bashrc/.config/starship.toml symlink), then overwritten by
    # the explicit starship block later in main() so it ends up pointing at
    # the real top-level starship.toml. The second write wins.
    Path(".config/starship.toml"): REPO_ROOT / "starship.toml",
}

WAYLAND_ONLY_CONFIG_TARGETS = {
    Path(".config/hypr"): REPO_ROOT / "bashrc" / ".config" / "hypr",
    Path(".config/waybar"): REPO_ROOT / "bashrc" / ".config" / "waybar",
    Path(".config/mako"): REPO_ROOT / "bashrc" / ".config" / "mako",
    Path(".config/mimeapps.list"): REPO_ROOT / "bashrc" / ".config" / "mimeapps.list",
}

NVIM_ENTRIES = {
    Path(".config/nvim/init.lua"): REPO_ROOT / "nvim" / "init.lua",
    Path(".config/nvim/lsp"): REPO_ROOT / "nvim" / "lsp",
    Path(".config/nvim/lua"): REPO_ROOT / "nvim" / "lua",
    Path(".config/nvim/stylua.toml"): REPO_ROOT / "nvim" / "stylua.toml",
    Path(".config/nvim/testfiles"): REPO_ROOT / "nvim" / "testfiles",
}

CAVEMAN_ENTRIES = {
    Path(".cursor/rules/caveman.mdc"): REPO_ROOT / "caveman" / "caveman.mdc",
    Path(".claude/CLAUDE.md"): REPO_ROOT / "caveman" / "CLAUDE.md",
}


def expected_links(darwin):
    expected = dict(COMMON_TOP_LEVEL)
    expected.update(COMMON_CONFIG_ENTRIES)
    if not darwin:
        expected.update(WAYLAND_ONLY_CONFIG_TARGETS)
    expected.update(NVIM_ENTRIES)
    expected.update(CAVEMAN_ENTRIES)
    return expected


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

    assert set(actual) == set(expected), (
        f"link set mismatch for {system}: "
        f"missing={set(expected) - set(actual)} "
        f"unexpected={set(actual) - set(expected)}"
    )
    for rel, target in expected.items():
        assert actual[rel] == target.resolve(), (
            f"{rel} -> {actual[rel]}, expected {target.resolve()}"
        )


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


def test_config_dir_is_real_not_symlinked(monkeypatch, fake_home):
    # The single safety property symlink.py is built around: ~/.config must
    # stay a real directory, never a symlink into the repo, or every app that
    # writes into $XDG_CONFIG_HOME would write straight into git.
    run_symlink_main(monkeypatch, fake_home, "Linux")
    config_dir = fake_home / ".config"
    assert config_dir.is_dir()
    assert not config_dir.is_symlink()


@pytest.mark.parametrize("system", ["Linux", "Darwin"])
def test_every_link_resolves_into_repo(monkeypatch, fake_home, system):
    run_symlink_main(monkeypatch, fake_home, system)
    links = links_under(fake_home)
    assert links, "expected at least one symlink to be created"
    for rel, target in links.items():
        assert target == REPO_ROOT or REPO_ROOT in target.parents, (
            f"{rel} resolves outside the repo: {target}"
        )


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
    decoy_target = fake_home / "elsewhere.sh"
    decoy_target.write_text("not the real z.sh\n")
    (fake_home / "z.sh").symlink_to(decoy_target)

    run_symlink_main(monkeypatch, fake_home, "Linux")

    assert not list(fake_home.glob("z.sh.bak-*"))
    z_link = fake_home / "z.sh"
    assert z_link.is_symlink()
    assert z_link.resolve() == (REPO_ROOT / "bashrc" / "z.sh").resolve()
