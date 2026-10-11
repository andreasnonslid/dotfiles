-- Which-key overlay for AeroSpace's leader (see parts/aerospace). AeroSpace does the work;
-- this only shows the hints. Colors come from colors.lua (scripts/theme.py).
local c = require("colors")
local hints = table.concat({
  "h j k l   focus          H J K L   move",
  "1-9   workspace          m 1-9   move window to workspace",
  "f   fullscreen           x   close window",
  "t   layout (s w e v b)   r   resize (h j k l)",
  "a   apps (t d)           q   session (l s)",
  "esc   cancel",
}, "\n")

local overlay, tap, timer

local function hide()
  if overlay then overlay:delete(); overlay = nil end
  if tap then tap:stop(); tap = nil end
  if timer then timer:stop(); timer = nil end
end

local function show()
  hide()
  local f = hs.screen.mainScreen():frame()
  local w, h = 620, 190
  overlay = hs.canvas.new({ x = f.x + (f.w - w) / 2, y = f.y + f.h - h - 40, w = w, h = h })
  overlay:level(hs.canvas.windowLevels.overlay)
  overlay:appendElements({
    type = "rectangle", action = "fill", roundedRectRadii = { xRadius = 10, yRadius = 10 },
    fillColor = { hex = c.bg, alpha = 0.95 },
    strokeColor = { hex = c.accent }, strokeWidth = 2,
  }, {
    type = "text", text = hints,
    textFont = "IosevkaTermNFM-Regular", textSize = 16, textColor = { hex = c.fg },
    frame = { x = 20, y = 14, w = w - 40, h = h - 28 },
  })
  overlay:show()
  -- Any key (the AeroSpace mode consumes it) or 6s dismisses the hints.
  tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function() hide(); return false end):start()
  timer = hs.timer.doAfter(6, hide)
end

hs.urlevent.bind("leader", show)

-- Menu-bar indicator: the current AeroSpace workspace. The macOS menu bar itself is left alone
-- (its left side holds the app menus); this adds one small item on the right.
local aerospace = hs.fs.attributes("/opt/homebrew/bin/aerospace") and "/opt/homebrew/bin/aerospace"
    or "/usr/local/bin/aerospace"
local item = hs.menubar.new()

local function refresh(name)
  if not name or name == "" then
    name = (hs.execute(aerospace .. " list-workspaces --focused", true) or ""):gsub("%s+", "")
  end
  item:setTitle(hs.styledtext.new(name ~= "" and name or "?", {
    color = { hex = c.accent }, font = { size = 13 },
  }))
end

item:setMenu(function()
  local out = hs.execute(aerospace .. " list-workspaces --all", true) or ""
  local menu = {}
  for ws in out:gmatch("%S+") do
    table.insert(menu, {
      title = "Workspace " .. ws,
      fn = function() hs.execute(aerospace .. " workspace " .. ws, true) end,
    })
  end
  return menu
end)

hs.urlevent.bind("workspace", function(_, params) refresh(params.name) end)
refresh()
