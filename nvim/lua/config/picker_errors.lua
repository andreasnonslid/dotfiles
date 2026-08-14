--- Soften snacks picker proc failures: clearer history text, no popup spam.
--- Review with <leader>fE or <leader>sn.
local M = {}

local PROC_TITLE = "Picker"

local function numlevel(level)
  if type(level) == "number" then
    return level
  end
  return vim.log.levels[(level or "info"):upper()] or vim.log.levels.INFO
end

local function has_fd()
  return vim.fn.executable("fd") == 1 or vim.fn.executable("fdfind") == 1
end

local function format_proc_error(msg)
  local cmd = msg:match("cmd: `([^`]+)`") or msg
  local cwd = vim.fn.getcwd(0)

  local lines = {
    "**File search command failed**",
    "",
    ("**cwd:** `%s`"):format(cwd),
    "",
    "```sh",
    cmd,
    "```",
  }

  if cmd:match("^rg ") and not has_fd() then
    table.insert(lines, "")
    table.insert(
      lines,
      "_Hint:_ install `fd` (`zypper install fd` / `apt install fd-find` / `cargo install fd-find`). "
        .. "Without it snacks falls back to `rg`, which also errors on empty trees."
    )
  elseif cmd:match("^rg ") then
    table.insert(lines, "")
    table.insert(lines, "_Hint:_ often harmless — empty directory or nothing matched the glob.")
  end

  return table.concat(lines, "\n")
end

local function is_proc_failure(msg)
  return type(msg) == "string" and msg:match("Command failed:") ~= nil
end

function M.is_suppressed(notif)
  local msg = notif.msg or ""
  local title = notif.title or ""
  if title == PROC_TITLE then
    return true
  end
  if msg:match("Command failed:") or msg:match("File search command failed") then
    return true
  end
  return false
end

function M.show_errors()
  require("snacks").picker.notifications({
    filter = function(notif)
      return M.is_suppressed(notif) or numlevel(notif.level) >= numlevel(vim.log.levels.ERROR)
    end,
  })
end

function M.setup()
  if M._done then
    return
  end
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    return
  end
  M._done = true

  local orig_error = snacks.notify.error
  snacks.notify.error = function(msg, opts)
    if is_proc_failure(msg) then
      msg = format_proc_error(msg)
      opts = vim.tbl_extend("force", { title = PROC_TITLE, id = "snacks.picker.proc" }, opts or {})
    end
    return orig_error(msg, opts)
  end

  vim.api.nvim_create_user_command("PickerErrors", M.show_errors, {
    desc = "Open picker/search error history",
  })

  if not has_fd() and not vim.g.picker_errors_fd_warned then
    vim.g.picker_errors_fd_warned = true
    vim.schedule(function()
      vim.notify(
        "nvim: no fd/fdfind — file picker uses rg and may log false errors on empty dirs. "
          .. "Install fd-find, or check :PickerErrors",
        vim.log.levels.WARN,
        { title = "dotfiles nvim", once = true }
      )
    end)
  end
end

return M
