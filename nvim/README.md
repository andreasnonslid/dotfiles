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
- **Tags** — `lua/config/tags.lua` drives ctags itself; no gutentags (see below)
- **Diff** — `'diffopt'` with `linematch:60` + histogram; diffview.nvim drives it

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
        ],
    },
}
```

`<leader>wo` picks a title. Activating `cd`s to `root` and adds extra `dirs` as LSP
workspace folders. Active title is stored in `workspaces-meta.json` next to it
(not in the file you edit).

| Key                        | Action                                           |
| -------------------------- | ------------------------------------------------ |
| `<leader>wo`               | Open picker (titles only)                        |
| `<leader>we`               | Edit `workspaces.json`                           |
| `<leader>wa`               | Oil: add this directory to the current workspace |
| `<leader>ff` / `fg` / `fw` | Files / grep / word in workspace dirs            |
| `<leader>Ff` / `Fg` / `Fw` | Same, git repo root only                         |

## Tags

`lua/config/tags.lua` does the gutentags job natively — `vim.system()`, no plugin, no
VimScript.

Lua alternatives do exist, contrary to what this file said first:
[gentags.nvim](https://github.com/linrongbin16/gentags.nvim) (~24 stars, last touched
Aug 2025) and [ctags.nvim](https://github.com/wsdjeg/ctags.nvim) (~15 stars);
[vim-gutentags](https://github.com/ludovicchabant/vim-gutentags) itself has had no
commit since April 2023. The native module was kept because it is roughly the same
size as the config needed to wire either of those up, it hooks straight into
`config.workspaces` for its scope, and it adds no dependency to a config that has
deliberately shed lspconfig, mason and nvim-cmp. That is a preference, not a verdict —
gentags.nvim is a reasonable swap, and it does one thing this does not (below).

**Known limitation:** every regeneration is a full rebuild. gutentags and gentags.nvim
do incremental per-file updates instead. On a repo of a few thousand files a rebuild is
cheap and cannot drift out of sync, which is the trade made here; on a very large
monorepo the incremental approach is the better one and this module is the wrong tool.

Tag files live **outside** the repo, in `~/.cache/nvim/tags/{dirname}-{hash}.tags`, one
per **workspace search dir** — so `<C-]>` reaches the extra `dirs` a workspace pulls in,
not just cwd. Regeneration is asynchronous, debounced 2s after a write, written to a
temp file and renamed into place so a lookup never sees a half-written index. In a git
repo the file list comes from `git ls-files --cached --others --exclude-standard`, so
`.gitignore` is honoured for free; elsewhere it falls back to `ctags -R` with a
hardcoded exclude list.

Needs **Universal Ctags** on `PATH` (`apt install universal-ctags`,
`brew install universal-ctags`, `zypper install ctags`). Exuberant Ctags is rejected
rather than used with the wrong flags — the index would silently be worse.

### The monorepo case

The layout this is actually built for: a huge monorepo you never open at the root,
opened one product at a time, where the product statically links libraries living
elsewhere in the tree.

```
<monorepo>/libs/…                 ← shared, linked in
<monorepo>/products/foo/…         ← what you actually open
```

clangd handles this badly, and it is worth knowing exactly how badly. Rooted at
`products/foo`, its compilation database describes that product. Lib **headers** resolve
because they are on the include path, so `<C-]>` onto a declaration works. Lib
**definitions** do not: those `.c` files never appear in this product's
`compile_commands.json`, so clangd never indexed them and cannot jump into them.
Nor can extra workspace folders help — clangd
[has no multi-root support](https://github.com/clangd/clangd/issues/1549); it infers one
compilation database from the first source file opened and ignores the rest. Which means
`<leader>wa` genuinely does nothing for clangd, though it works for `lua_ls` and
`pyright`.

That gap is the whole reason the ctags index exists here. Add the libs tree as an extra
search dir and it is covered:

```jsonc
{
    "foo": {
        "root": "/abs/path/monorepo/products/foo",
        "dirs": ["/abs/path/monorepo/libs"],
    },
}
```

Either `<leader>wa` from an oil buffer in `libs/`, or `<leader>we` to edit it directly.
Both dirs then get their own index and `'tags'` lists both, so `<leader>fT` on a lib
function reaches its definition where clangd stops at the declaration.

Neither dir is a git _root_, and that is handled: `git ls-files` is asked from the
directory itself, which lists that subtree only and still honours `.gitignore`. The
monorepo is never indexed whole, and build output never lands in the index.

### Tags vs LSP

They do not overlap, and the split is worth knowing:

Neovim's `lsp-defaults` set buffer-local `'tagfunc'` to `vim.lsp.tagfunc` when a client
attaches. So on a buffer backed by one of `lsp/*.lua`, **`<C-]>` is answered by the
language server and never opens a tags file**. The ctags index covers what is left:
filetypes with no server configured here, files outside a server's root, and any
"just index this pile of source" case. `<leader>fT` suspends `'tagfunc'` for the
duration of the jump to force the ctags path (buffer-local, and restored on the buffer
it was saved from — a successful jump lands in a different one). `<leader>ft` lists via
`vim.fn.taglist()`, which reads `'tags'` directly and never consults `'tagfunc'`.

### Keys

Native tag keys are left alone, with one exception — `g]` is taken by `mini.ai`
(its "go to right edge of textobject" mapping). `g<C-]>` is the better key anyway:
`:tjump` jumps straight through when a name is unique and only shows the list when it
is not. `nvim/tests/keymaps_spec.lua` asserts all of this, in both directions.

| Key      | Action                                     |
| -------- | ------------------------------------------ |
| `<C-]>`  | Jump to tag under cursor (LSP if attached) |
| `<C-t>`  | Pop the tag stack                          |
| `g]`     | `:tselect` — list every match              |
| `g<C-]>` | `:tjump` — jump, or list if ambiguous      |
| `<C-w>]` | Open the tag in a split                    |
| `<C-w>}` | Preview the tag                            |

Added on top, for what has no native key:

| Key          | Action                                                    |
| ------------ | --------------------------------------------------------- |
| `<leader>ft` | Pick a tag — `Snacks.picker.tags()`, kind icons + preview |
| `<leader>fT` | Tag under cursor via **ctags**, bypassing LSP `'tagfunc'` |
| `<leader>ct` | `:TagsUpdate` — regenerate every workspace dir            |

`:TagsInfo` reports each index's path, size and age.

## Diff review

[diffview-plus.nvim](https://github.com/dlyongemallo/diffview-plus.nvim) — the
file-set-level tool, where gitsigns stays the hunk-level one for the buffer being
edited.

This is the maintained fork. Upstream `sindrets/diffview.nvim` has had no commit since
June 2024 and its author has been unreachable; `dlyongemallo` picked it up, is hundreds
of commits ahead, and other projects (Neogit among them) have moved their
recommendation across. It is a drop-in — same commands, same option table. The fork
also adds a unified inline-diff layout, Jujutsu support, and a review workflow the
original lacks: `w` marks files reviewed, `H` hides the ones already done so the panel
shows only what is left.

It implements no diff algorithm of its own. It asks git for the file list
(`git diff --name-status <rev>`), fills a scratch buffer per side with
`git show <rev>:<path>`, and turns on **Neovim's built-in diff mode** over the pair.
The highlighting, `]c`/`[c`, `do`/`dp` and folding are all the native engine — diffview
supplies the file panel, the revision plumbing, and a tabpage that keeps a review from
scattering across windows. Which is why `'diffopt'` in `config/options.lua` matters:
`linematch:60` re-aligns lines inside a changed hunk so a one-word edit highlights as
one word rather than two wholly replaced lines, and `algorithm:histogram` +
`indent-heuristic` pick hunk boundaries that follow code structure.

| Key          | Action                                                         |
| ------------ | -------------------------------------------------------------- |
| `<leader>gd` | Working tree vs index (toggle — press again to close)          |
| `<leader>gD` | The last commit (`HEAD~1`)                                     |
| `<leader>gr` | **Review**: this branch vs its base, `base...HEAD` (PR-shaped) |
| `<leader>gh` | Repo history (visual mode: history of the selected lines)      |
| `<leader>gH` | This file's history, `--follow` through renames                |

Inside a view: `q` closes, `<leader>e` toggles the file panel, `<Tab>`/`<S-Tab>` step
through files, `]c`/`[c` move by change, `do`/`dp` obtain/put a hunk.

`<leader>gr` resolves the base from `refs/remotes/origin/HEAD`, falling back to
`origin/main`, `origin/master`, `main`, `master`. The `...` form diffs against the merge
base, so commits that landed on the base meanwhile stay out of the review.

Merge conflicts get the 3-way layout automatically (`:DiffviewOpen` during a conflicted
merge): OURS | working copy | THEIRS, with the working copy in the middle so `2do`/`3do`
pull from either side.

## Plugins (minimal set)

| Plugin                        | Role                                                 |
| ----------------------------- | ---------------------------------------------------- |
| snacks.nvim                   | picker, grep, notifications                          |
| toggleterm.nvim               | floating terminal (`<F4>`), lazygit (`<leader>gg`)   |
| oil.nvim                      | file browser                                         |
| gitsigns.nvim                 | git gutter / hunks                                   |
| diffview.nvim                 | diff / merge review over the built-in diff engine    |
| conform.nvim                  | format-on-save (`ruff`, `clang-format`, `stylua`, …) |
| nvim-treesitter + textobjects | parsers + `af`/`if`/`]f`                             |
| mini.\*                       | icons, pairs, ai, surround                           |
| flash.nvim                    | jump labels                                          |
| justlists                     | personal list workflow                               |
| persistence.nvim              | sessions                                             |
| indent-blankline              | indent guides                                        |
| noctishc                      | colorscheme                                          |

Install `fd` (`zypper install fd` / `apt install fd-find`) so the file picker
does not fall back to `rg`. Notification history: `<leader>sn`.

Symlinked into `~/.config/nvim` by `symlink.py`; see the root `README.md` for the
overall setup flow.
