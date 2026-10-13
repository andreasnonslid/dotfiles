-- Which-key overlay for AeroSpace's leader (see parts/aerospace). AeroSpace does the work;
-- this only shows the hints. Colors come from colors.lua (scripts/theme.py).
local c = require("colors")
local pages = {
    leader = table.concat({
        "h j k l   focus          H J K L   move",
        "1-9   workspace          m 1-9   move window to workspace",
        "f   fullscreen           x   close window",
        "t   layout (s w e)       r   resize (h j k l)",
        "a   apps (t d)           q   session (l s r)",
        "esc hyper   cancel",
    }, "\n"),
    session = table.concat({
        "l   lock                 s   shutdown",
        "r   restart",
        "esc hyper   cancel",
    }, "\n"),
    resize = table.concat({
        "h l   width              k j   height",
        "esc hyper   cancel",
    }, "\n"),
    move = table.concat({
        "1-9   move window to that workspace",
        "esc hyper   cancel",
    }, "\n"),
    layout = table.concat({
        "s   stack vertical       w   stack horizontal",
        "e   tiles",
        "esc hyper   cancel",
    }, "\n"),
    launch = table.concat({
        "t   Ghostty              d   Raycast",
        "esc hyper   cancel",
    }, "\n"),
}
local enter_page =
    { q = "session", r = "resize", t = "layout", m = "move", a = "launch" }
local keep_open = { resize = { h = true, j = true, k = true, l = true } }

local aerospace = hs.fs.attributes("/opt/homebrew/bin/aerospace")
        and "/opt/homebrew/bin/aerospace"
    or "/usr/local/bin/aerospace"
local overlay, tap, timer, page

local function dismiss_overlay()
    if overlay then
        overlay:delete()
        overlay = nil
    end
end

local function stop_tap()
    if tap then
        tap:stop()
        tap = nil
    end
end

local function stop_timer()
    if timer then
        timer:stop()
        timer = nil
    end
end

local function back_to_main()
    page = "leader"
    dismiss_overlay()
    stop_tap()
    stop_timer()
    hs.execute(aerospace .. " mode main", true)
end

local function arm(seconds)
    stop_timer()
    timer = hs.timer.doAfter(seconds, back_to_main)
end

local function set_page(name)
    page = name
    if overlay then
        overlay:elementAttribute(2, "text", pages[name])
    end
    arm(6)
end

local function show(initial)
    page = initial or "leader"
    dismiss_overlay()
    stop_tap()
    stop_timer()
    local f = hs.screen.mainScreen():frame()
    local w, h = 620, 190
    overlay = hs.canvas.new({
        x = f.x + (f.w - w) / 2,
        y = f.y + f.h - h - 40,
        w = w,
        h = h,
    })
    overlay:level(hs.canvas.windowLevels.overlay)
    overlay:appendElements({
        type = "rectangle",
        action = "fill",
        roundedRectRadii = { xRadius = 10, yRadius = 10 },
        fillColor = { hex = c.bg, alpha = 0.95 },
        strokeColor = { hex = c.accent },
        strokeWidth = 2,
    }, {
        type = "text",
        text = pages[page],
        textFont = "IosevkaTermNFM-Regular",
        textSize = 16,
        textColor = { hex = c.fg },
        frame = { x = 20, y = 14, w = w - 40, h = h - 28 },
    })
    overlay:show()
    -- Ignore the Hyper chord that opened this card until it is released.
    -- A later Hyper press with no other key cancels (whoops). Hyper+Space is
    -- also bound in AeroSpace to hammerspoon://dismiss.
    local function modsUp(flags)
        return not (
            flags.ctrl
            or flags.alt
            or flags.cmd
            or flags.shift
            or flags.fn
        )
    end
    -- Already released when the card appears: the next Hyper press cancels.
    -- Still held: wait for that release, and do not treat it as cancel.
    local hyperArmed = modsUp(hs.eventtap.checkKeyboardModifiers())
    local hyperDown, hyperUsed = false, false
    tap = hs.eventtap
        .new({
            hs.eventtap.event.types.keyDown,
            hs.eventtap.event.types.flagsChanged,
        }, function(ev)
            local flags = ev:getFlags()
            if ev:getType() == hs.eventtap.event.types.flagsChanged then
                if not hyperArmed then
                    if modsUp(flags) then
                        hyperArmed = true
                    end
                    return false
                end
                if flags.ctrl and flags.alt and flags.cmd then
                    if not hyperDown then
                        hyperDown, hyperUsed = true, false
                    end
                    return false
                end
                if hyperDown and modsUp(flags) then
                    hyperDown = false
                    if not hyperUsed and overlay then
                        back_to_main()
                    end
                elseif hyperDown then
                    hyperDown = false
                end
                return false
            end
            if hyperDown then
                hyperUsed = true
            end
            local key = hs.keycodes.map[ev:getKeyCode()]
            -- q/r/t/m/a switch this card to that mode's keys. Swallow a repeat of the
            -- same key so it cannot immediately leave the mode. Other keys pass through
            -- to AeroSpace; resize arrows keep the card up.
            if key == "escape" then
                page = "leader"
                dismiss_overlay()
                stop_tap()
                stop_timer()
                return false
            end
            if page == "leader" and enter_page[key] then
                set_page(enter_page[key])
                return false
            end
            if page ~= "leader" and enter_page[key] == page then
                arm(6)
                return true
            end
            if keep_open[page] and keep_open[page][key] then
                arm(6)
                return false
            end
            page = "leader"
            dismiss_overlay()
            stop_tap()
            stop_timer()
            return false
        end)
        :start()
    arm(6)
end

hs.urlevent.bind("dismiss", function()
    page = "leader"
    dismiss_overlay()
    stop_tap()
    stop_timer()
end)
hs.urlevent.bind("lock", function()
    hs.caffeinate.lockScreen()
end)
hs.urlevent.bind("leader", function()
    show("leader")
end)
hs.urlevent.bind("submode", function(_, params)
    local name = params and params.name
    if not pages[name] then
        return
    end
    if overlay then
        set_page(name)
    else
        show(name)
    end
end)
