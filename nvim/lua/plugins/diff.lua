-- Diff review.
--
-- How this works: diffview does not implement a diff algorithm. It asks git for
-- the file list (`git diff --name-status <rev>`), fills a scratch buffer per side
-- with `git show <rev>:<path>`, and then turns on Neovim's own diff mode over the
-- pair. The colouring, `]c`/`[c`, `do`/`dp` and the fold behaviour are all the
-- built-in diff engine — diffview supplies the file panel, the revision plumbing
-- and the tabpage that keeps a review from scattering across windows.
--
-- Which means the built-in engine's settings decide how good the diff looks;
-- those live in config.options ('diffopt' with linematch + the histogram
-- algorithm).
--
-- gitsigns (lua/plugins/git.lua) stays the hunk-level tool for the buffer being
-- edited. This is the file-set-level tool for reviewing a change as a whole.

local function git(...)
  local cmd = { "git", ... }
  local ok, res = pcall(function()
    return vim.system(cmd, { text = true }):wait(2000)
  end)
  if ok and res.code == 0 then
    return vim.trim(res.stdout or "")
  end
end

--- The branch this one forked from: what the remote calls its default head, or
--- the first plausible local/remote fallback.
local function base_ref()
  local head = git("symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD")
  if head and head ~= "" then
    return head
  end
  for _, candidate in ipairs({ "origin/main", "origin/master", "main", "master" }) do
    if git("rev-parse", "--verify", "--quiet", candidate) then
      return candidate
    end
  end
end

--- Everything this branch adds on top of its base — `base...HEAD`, the
--- merge-base diff, so commits that landed on the base meanwhile stay out of it.
--- This is the same set of changes a pull request shows.
local function review_branch()
  local base = base_ref()
  if not base then
    vim.notify("diff: no base branch found (looked for origin/HEAD, main, master)", vim.log.levels.WARN)
    return
  end
  local current = git("rev-parse", "--abbrev-ref", "HEAD")
  if current and base:gsub("^origin/", "") == current then
    vim.notify(("diff: already on %s — nothing to review against %s"):format(current, base), vim.log.levels.WARN)
    return
  end
  vim.cmd("DiffviewOpen " .. base .. "...HEAD")
end

--- A second press from inside a review closes it.
local function toggle()
  local lib = package.loaded["diffview.lib"]
  if lib and lib.get_current_view() then
    vim.cmd("DiffviewClose")
  else
    vim.cmd("DiffviewOpen")
  end
end

local close_and_toggle_panel = {
  { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
  { "n", "<leader>e", "<cmd>DiffviewToggleFiles<CR>", { desc = "Toggle File Panel" } },
}

return {
  {
    "dlyongemallo/diffview-plus.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { layout = "diff2_horizontal", winbar_info = true },
        -- 3-way for conflicts: OURS | working copy | THEIRS, working copy in the
        -- middle so 2do/3do pull from either side into it.
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true, winbar_info = true },
        file_history = { layout = "diff2_horizontal", winbar_info = true },
      },
      file_panel = {
        listing_style = "tree",
        tree_options = { flatten_dirs = true, folder_statuses = "only_folded" },
        win_config = { position = "left", width = 32 },
      },
      hooks = {
        -- Global 'list'/'relativenumber' add visual noise to a side-by-side diff,
        -- where the columns already have to line up across two windows.
        diff_buf_read = function()
          vim.opt_local.wrap = false
          vim.opt_local.list = false
          vim.opt_local.relativenumber = false
        end,
      },
      keymaps = {
        view = close_and_toggle_panel,
        file_panel = close_and_toggle_panel,
        file_history_panel = close_and_toggle_panel,
      },
    },
    keys = {
      { "<leader>gd", toggle, desc = "Diff: working tree" },
      { "<leader>gD", "<cmd>DiffviewOpen HEAD~1<CR>", desc = "Diff: last commit" },
      { "<leader>gr", review_branch, desc = "Diff: branch vs base (review)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<CR>", desc = "Diff: repo history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory --follow %<CR>", desc = "Diff: this file's history" },
      {
        "<leader>gh",
        "<Esc><Cmd>'<,'>DiffviewFileHistory<CR>",
        mode = "v",
        desc = "Diff: history of selection",
      },
    },
  },
}
