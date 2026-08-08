# SSH setup scripts

- **setup_ssh_key.sh** - Create, delete, rename, or list SSH keys. Git identity is set separately via `~/.local/secrets/git/{personal,work}.gitconfig` (see root README.md), not by this script.
- **setup_git_host.sh** - Add a `Host` entry for a git host to `~/.local/secrets/ssh/<host>.conf`, picking the SSH key whose `.pub` comment matches a given email domain. Generalises the old AutoStore-only `setup_AS_git.sh`; e.g. `./setup_git_host.sh as-git.autostoresystem.com autostoresystem.com`.

## `~/.ssh/config`

`~/.ssh/config` is tracked (symlinked from `bashrc/.ssh/config` by `symlink.py`, M30) and carries no host- or identity-specific entries, for the same reason the tracked `.gitconfig` carries no `[user]` section: it's in git, so anything specific would leak. Per-host blocks (git hosts, VPN jump hosts, ...) go in `~/.local/secrets/ssh/*.conf` instead, pulled in via an `Include` line -- `setup_git_host.sh` writes there. `~/.ssh/config.darwin` holds the one macOS-only keyword (`UseKeychain`) that a non-Apple OpenSSH build refuses to parse; symlink.py links it in only on darwin, and the base config's `Include` silently skips it elsewhere.
