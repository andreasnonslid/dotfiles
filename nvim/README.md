# nvim config

Hand-rolled on [lazy.nvim](https://github.com/folke/lazy.nvim) — not the LazyVim
distro. `init.lua` wires up `config.options`, `config.autocmds`, `config.keymaps`,
`config.lazy` (the lazy.nvim bootstrap + plugin spec) and `config.workspaces` in that
order; plugins live under `lua/plugins/`.

LSP servers are configured directly with native `vim.lsp.config` (`lsp/*.lua`) rather
than through an LSP-manager plugin like `mason.nvim` or `nvim-lspconfig`. Each file
under `lsp/` names a server (`bashls`, `clangd`, `lua_ls`, `pyright`, `ruff`) and the
binary is expected to already be on `PATH` — installed by the OS-level provisioning
(`macos/Brewfile`, `linux/*.sh`), not by nvim itself.

Picking (files, grep, buffers, ...) is [snacks.nvim](https://github.com/folke/snacks.nvim),
not telescope — see `lua/plugins/snacks-config.lua`.

Symlinked into `~/.config/nvim` by `symlink.py`; see the root `README.md` for the
overall setup flow.
