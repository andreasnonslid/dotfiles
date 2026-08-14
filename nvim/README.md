# nvim config

Hand-rolled on [lazy.nvim](https://github.com/folke/lazy.nvim) — not the LazyVim
distro. `init.lua` wires up `config.options`, `config.autocmds`, `config.keymaps`,
`config.lsp`, `config.lazy` (the lazy.nvim bootstrap + plugin spec) and
`config.workspaces` in that order; plugins live under `lua/plugins/`.

Targets **Neovim 0.11+** (tested on 0.12.x). On Linux, `bashrc/.bashrc` prepends
`~/.local/opt/nvim-linux-x86_64/bin` (or `/opt/nvim-linux-x86_64/bin`) ahead of the
distro package — install/upgrade via `linux/ubuntu.sh` or the [release tarball](https://github.com/neovim/neovim/releases).

## Native core (no plugin)

- **LSP** — `lsp/*.lua` + `vim.lsp.config` / `vim.lsp.enable` (no `nvim-lspconfig` / mason)
- **Completion** — `vim.lsp.completion` + `vim.snippet` on `LspAttach` (no nvim-cmp / blink). `<CR>` accepts a selected item; `grn` is rename.
- **Diagnostics** — `vim.diagnostic.*`; picker UI via snacks (`<leader>fd` / `<leader>fD`)
- **Defaults** — `gra`/`grn`/`grr`/`grt`/`gri`/`K` from `lsp-defaults`; custom `gd`/`gD` kept
- **Statusline** — Neovim 0.12 default (`laststatus=3`)
- **Folds** — treesitter, open on load; `<leader>z` toggles (`zR`/`zM` builtins)

## Workspaces

Config lives **outside repos**: `~/.local/state/nvim/workspaces.json`.
`<leader>we` creates a titled entry for cwd if none exists, then opens the file.
`:w` / `:q` / `q` work. Title is `{dirname}`, or `{dirname}-2` if taken.

```jsonc
{
  "FirmwareApp": {
    "root": "/home/anh/fw/app",
    "dirs": [
      // extra search/LSP dirs, e.g. "/abs/path/to/lib"
    ]
  }
}
```

`<leader>wo` picks a title. Activating `cd`s to `root` and adds extra `dirs` as LSP
workspace folders. Active title is stored in `workspaces-meta.json` next to it
(not in the file you edit).

| Key | Action |
|-----|--------|
| `<leader>wo` | Open picker (titles only) |
| `<leader>we` | Edit `workspaces.json` |
| `<leader>wa` | Oil: add this directory to the current workspace |
| `<leader>ff` / `fg` / `fw` | Files / grep / word in workspace dirs |
| `<leader>Ff` / `Fg` / `Fw` | Same, git repo root only |

## Plugins (minimal set)

| Plugin | Role |
|--------|------|
| snacks.nvim | picker, grep, terminal, notifications |
| oil.nvim | file browser |
| gitsigns.nvim | git gutter / hunks |
| conform.nvim | format-on-save (`ruff`, `clang-format`, `stylua`, …) |
| nvim-treesitter + textobjects | parsers + `af`/`if`/`]f` |
| mini.* | icons, pairs, ai, surround |
| flash.nvim | jump labels |
| justlists | personal list workflow |
| persistence.nvim | sessions |
| indent-blankline | indent guides |
| noctishc | colorscheme |

Install `fd` (`zypper install fd` / `apt install fd-find`) so the file picker
does not fall back to `rg`. Notification history: `<leader>sn`.

Symlinked into `~/.config/nvim` by `symlink.py`; see the root `README.md` for the
overall setup flow.
