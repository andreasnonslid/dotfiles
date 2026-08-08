# zsh adapter

Empty for now. `core/`, `git/` and `tools/` are already shell-agnostic
(M06); this directory is where the zsh-only pieces land as their own
backlog items ship:

- the starship prompt setup (M07, replacing the hand-rolled bash `PS1`)
- `bashrc/.zshrc` sourcing core → git → tools → here (M08)
- `compdef`-based completions replacing `tools/completion.sh`'s
  `complete`/`__git_complete` calls, which are bash-only (M11)

See `bash/` for the equivalent bash-only adapter, already populated.
