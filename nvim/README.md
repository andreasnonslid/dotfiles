# nvim config

Hand-rolled on [lazy.nvim](https://github.com/folke/lazy.nvim) — not the LazyVim
distro. `init.lua` wires up `config.options`, `config.autocmds`, `config.keymaps`,
`config.lazy` (the lazy.nvim bootstrap + plugin spec) and `config.workspaces` in that
order; plugins live under `lua/plugins/`.

Targets **Neovim 0.11+** (tested on 0.12.x). On Linux, `bashrc/.bashrc` prepends
`~/.local/opt/nvim-linux-x86_64/bin` (or `/opt/nvim-linux-x86_64/bin`) ahead of the
distro package — install/upgrade via `linux/ubuntu.sh` or the [release tarball](https://github.com/neovim/neovim/releases).

## Native core (no plugin)

- **LSP** — `lsp/*.lua` + `vim.lsp.config` / `vim.lsp.enable` (no `nvim-lspconfig` / mason)
- **Completion** — `vim.lsp.completion` + `vim.snippet` on `LspAttach` (no nvim-cmp / blink)
- **Diagnostics** — `vim.diagnostic.*`; picker UI via snacks
- **Defaults** — `gra`/`grn`/`grr`/`grt`/`gri`/`K` from `lsp-defaults`; custom `gd`/`gD` kept

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
| **workspaces** | multi-dir search; root kept for LSP/`compile_commands` — `<leader>Wo` open, `Wn` new, `We` edit, `Wa` add dir |
| persistence.nvim | sessions |
| indent-blankline | indent guides |
| noctishc | colorscheme |

Symlinked into `~/.config/nvim` by `symlink.py`; see the root `README.md` for the
overall setup flow.
