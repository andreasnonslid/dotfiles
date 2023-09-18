# Useful things to remember

choco install iosevka-nerd-font

choco install tree-sitter

Details: (https://community.chocolatey.org/packages?q=iosevka)

pip install neovim

npm install -g neovim

# Dotfiles

## Commit Message Enforcement

This repository enforces a professional commit message style using a portable Perl commit-msg hook stored in `.githooks/commit-msg`.

```sh
git config core.hooksPath .githooks
```

**To enable commit message enforcement after cloning:**

```sh
git config core.hooksPath .githooks
```

This ensures all contributors follow the same commit message standards, improving project history and collaboration.

**Commit message format:**

- `<type>(optional-scope): <summary>`
- Allowed types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
- Type: lower-case, required
- Scope: optional, lower-case, no spaces
- Summary: 2-10 words, 10-50 characters
- Header: max 72 characters

---
