-- Workspace chips in the menu bar, same idea as AeroSpace's i3Ordered style:
-- filled chip for the workspace you are on, outline for the others that have windows.
-- Each chip is its own menu-bar item, so a click focuses that workspace.
-- Highlight follows AeroSpace. animations = true rebuilds the items on every change.
local animations = false
local aerospace = hs.fs.attributes("/opt/homebrew/bin/aerospace")
        and "/opt/homebrew/bin/aerospace"
    or "/usr/local/bin/aerospace"

local bars = {}
local pending
local sub
local lastSig
local lastStructure

local function run(args)
    local out = hs.execute(string.format("%q %s", aerospace, args))
    return out or ""
end

local function inkColor()
    if hs.host.interfaceStyle() == "Dark" then
        return { white = 1, alpha = 1 }
    end
    return { white = 0, alpha = 1 }
end

local function withAlpha(color, alpha)
    local copy = {}
    for k, v in pairs(color) do
        copy[k] = v
    end
    copy.alpha = alpha
    return copy
end

local function chipImage(label, kind, dim, fullscreen)
    local ink = inkColor()
    local alpha = dim and 0.45 or 1
    ink = withAlpha(ink, alpha)
    local fill = withAlpha(ink, alpha * 0.28)
    local h, w = 18, 18
    if #label > 1 then
        w = 8 + 8 * #label
    end
    local canvas = hs.canvas.new({ x = 0, y = 0, w = w, h = h })
    local elements = {}
    if kind == "fill" then
        elements[#elements + 1] = {
            type = "rectangle",
            action = "fill",
            roundedRectRadii = { xRadius = 3, yRadius = 3 },
            fillColor = fill,
            frame = { x = 1, y = 1, w = w - 2, h = h - 2 },
        }
        elements[#elements + 1] = {
            type = "text",
            text = label,
            textFont = "Helvetica-Bold",
            textSize = 12,
            textAlignment = "center",
            textColor = ink,
            frame = { x = 0, y = 2, w = w, h = h - 2 },
        }
    elseif kind == "mode" then
        elements[#elements + 1] = {
            type = "oval",
            action = "stroke",
            strokeColor = ink,
            strokeWidth = 1.5,
            frame = { x = 1, y = 1, w = w - 2, h = h - 2 },
        }
        elements[#elements + 1] = {
            type = "text",
            text = label,
            textFont = "Helvetica-Bold",
            textSize = 11,
            textAlignment = "center",
            textColor = ink,
            frame = { x = 0, y = 2, w = w, h = h - 2 },
        }
    else
        elements[#elements + 1] = {
            type = "rectangle",
            action = "stroke",
            strokeColor = ink,
            strokeWidth = 1.5,
            roundedRectRadii = { xRadius = 3, yRadius = 3 },
            frame = { x = 1.5, y = 1.5, w = w - 3, h = h - 3 },
        }
        elements[#elements + 1] = {
            type = "text",
            text = label,
            textFont = "Helvetica-Bold",
            textSize = 12,
            textAlignment = "center",
            textColor = ink,
            frame = { x = 0, y = 2, w = w, h = h - 2 },
        }
    end
    if fullscreen then
        elements[#elements + 1] = {
            type = "rectangle",
            action = "stroke",
            strokeColor = ink,
            strokeWidth = 1,
            strokeDashPattern = { 2, 2 },
            roundedRectRadii = { xRadius = 3, yRadius = 3 },
            frame = { x = 0.5, y = 0.5, w = w - 1, h = h - 1 },
        }
    end
    canvas:appendElements(elements)
    local image = canvas:imageFromCanvas()
    canvas:delete()
    if image then
        image:template(false)
    end
    return image
end

local function state()
    local windows = {}
    for line in
        run(
            "list-windows --all --format '%{workspace}%{tab}%{window-is-fullscreen}'"
        ):gmatch("[^\n]+")
    do
        local name, full = line:match("^(.-)\t(%S+)$")
        if name then
            local info = windows[name] or { n = 0, full = false }
            info.n = info.n + 1
            if full == "true" then
                info.full = true
            end
            windows[name] = info
        end
    end
    local entries = {}
    for line in
        run(
            "list-workspaces --all --format '%{workspace}%{tab}%{workspace-is-focused}%{tab}%{workspace-is-visible}'"
        ):gmatch("[^\n]+")
    do
        local name, focused, visible = line:match("^(.-)\t(%S+)\t(%S+)$")
        if name then
            local info = windows[name] or { n = 0, full = false }
            if visible == "true" or info.n > 0 then
                entries[#entries + 1] = {
                    key = "ws-" .. name,
                    label = name,
                    kind = focused == "true" and "fill" or "outline",
                    dim = focused ~= "true",
                    full = info.full,
                    command = string.format(
                        "%q workspace -- %q",
                        aerospace,
                        name
                    ),
                }
            end
        end
    end
    table.sort(entries, function(a, b)
        local na, nb = tonumber(a.label), tonumber(b.label)
        if na and nb then
            return na < nb
        end
        return a.label < b.label
    end)
    local mode = run("list-modes --current"):match("^(%S+)")
    if mode and mode ~= "main" then
        table.insert(entries, 1, {
            key = "mode",
            label = mode:sub(1, 1):upper(),
            kind = "mode",
            dim = false,
            full = false,
            command = string.format("%q mode main", aerospace),
        })
    end
    return entries
end

local function signature(entries)
    local parts = { hs.host.interfaceStyle() or "Light" }
    for _, entry in ipairs(entries) do
        parts[#parts + 1] = table.concat({
            entry.key,
            entry.kind,
            entry.dim and "d" or "b",
            entry.full and "f" or "n",
        }, ":")
    end
    return table.concat(parts, "|")
end

local function visualSig(entry)
    return table.concat({
        hs.host.interfaceStyle() or "Light",
        entry.kind,
        entry.dim and "d" or "b",
        entry.full and "f" or "n",
    }, ":")
end

local function structureSig(entries)
    local parts = {}
    for _, entry in ipairs(entries) do
        parts[#parts + 1] = entry.key
    end
    return table.concat(parts, "|")
end

local function setChipIcon(bar, entry)
    local image = chipImage(entry.label, entry.kind, entry.dim, entry.full)
    if image then
        bar:setIcon(image, false)
    end
end

local function recreate(entries)
    for _, slot in pairs(bars) do
        slot.item:delete()
    end
    bars = {}
    -- New status items are inserted on the left, so create right-to-left.
    for i = #entries, 1, -1 do
        local entry = entries[i]
        local bar = hs.menubar.new(true, "dotfiles-aero-" .. entry.key)
        if bar then
            setChipIcon(bar, entry)
            local command = entry.command
            bar:setClickCallback(function()
                hs.execute(command)
            end)
            bars[entry.key] = {
                item = bar,
                sig = visualSig(entry),
                label = entry.label,
                kind = entry.kind,
                dim = entry.dim,
                full = entry.full,
            }
        end
    end
    lastStructure = structureSig(entries)
end

local function showChips(entries)
    if animations then
        local sig = signature(entries)
        if sig == lastSig then
            return
        end
        lastSig = sig
        recreate(entries)
        return
    end
    if structureSig(entries) ~= lastStructure then
        recreate(entries)
        return
    end
    for _, entry in ipairs(entries) do
        local slot = bars[entry.key]
        local sig = visualSig(entry)
        if slot and slot.sig ~= sig then
            setChipIcon(slot.item, entry)
            slot.label = entry.label
            slot.kind = entry.kind
            slot.dim = entry.dim
            slot.full = entry.full
            slot.sig = sig
        end
    end
end

local lineBuf = ""
local schedule

local function highlight(name)
    for key, slot in pairs(bars) do
        if slot.kind ~= "mode" then
            local focused = key == "ws-" .. name
            local kind = focused and "fill" or "outline"
            local dim = not focused
            if slot.kind ~= kind or slot.dim ~= dim then
                slot.kind = kind
                slot.dim = dim
                setChipIcon(slot.item, slot)
                slot.sig = visualSig(slot)
            end
        end
    end
end

local function onSubscribe(_, stdout, stderr)
    local chunk = stdout or stderr
    if not chunk or chunk == "" then
        return true
    end
    lineBuf = lineBuf .. chunk
    while true do
        local line, rest = lineBuf:match("^([^\n]*)\n(.*)$")
        if not line then
            break
        end
        lineBuf = rest
        local event = line:match('"_event"%s*:%s*"([^"]+)"')
        local workspace = line:match('"workspace"%s*:%s*"([^"]+)"')
        if event == "focused-workspace-changed" and workspace then
            highlight(workspace)
            if schedule then
                schedule()
            end
        elseif schedule then
            schedule()
        end
    end
    return true
end

local function refresh()
    showChips(state())
end

schedule = function()
    if pending then
        return
    end
    pending = hs.timer.doAfter(0.15, function()
        pending = nil
        refresh()
    end)
end

local function watch()
    if sub then
        sub:terminate()
        sub = nil
    end
    sub = hs.task.new(
        aerospace,
        function()
            hs.timer.doAfter(1, watch)
        end,
        onSubscribe,
        {
            "subscribe",
            "focused-workspace-changed",
            "mode-changed",
            "window-detected",
        }
    )
    sub:start()
end

windowWatch = hs.window.filter.new(true)
windowWatch:subscribe({
    hs.window.filter.windowCreated,
    hs.window.filter.windowDestroyed,
    hs.window.filter.windowFullscreened,
    hs.window.filter.windowUnfullscreened,
}, schedule)

themeWatch = hs.distributednotifications.new(
    schedule,
    "AppleInterfaceThemeChangedNotification"
)

watch()
refresh()
