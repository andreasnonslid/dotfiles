-- Custom autocommands

-- Some bundled treesitter highlight queries have malformed syntax that
-- raises out of vim.treesitter.query.parse and crashes consumers (e.g.
-- the snacks picker's row highlighter). Wrap parse so failures degrade
-- to "no highlight" instead of taking the picker down. The first failure
-- per (lang, query-length) is reported so the offender stays visible.
do
  local orig = vim.treesitter.query.parse
  local seen = {}
  vim.treesitter.query.parse = function(lang, query)
    local ok, result = pcall(orig, lang, query)
    if ok then
      return result
    end
    local key = (lang or "?") .. ":" .. tostring(#(query or ""))
    if not seen[key] then
      seen[key] = true
      vim.schedule(function()
        vim.notify(
          "treesitter query.parse failed for "
            .. (lang or "?")
            .. " (suppressing duplicates): "
            .. tostring(result),
          vim.log.levels.WARN
        )
      end)
    end
    return nil
  end
end
