-- Windows AeroSpace refuses to manage (no workspace, no chip). Raise them
-- so they cannot sit unnoticed. A normal new window is given a moment to
-- join AeroSpace before it counts as a stray.
local aerospace = hs.fs.attributes("/opt/homebrew/bin/aerospace")
        and "/opt/homebrew/bin/aerospace"
    or "/usr/local/bin/aerospace"

local python = (hs.execute("/bin/bash -lc 'command -v python3'") or ""):gsub(
    "%s+$",
    ""
)
if python == "" then
    python = "/usr/bin/python3"
end

local listCmd = python
    .. [[ -c 'import Quartz
opts=Quartz.kCGWindowListOptionOnScreenOnly|Quartz.kCGWindowListExcludeDesktopElements
for w in Quartz.CGWindowListCopyWindowInfo(opts, Quartz.kCGNullWindowID):
    if w.get("kCGWindowLayer")!=0: continue
    b=w.get("kCGWindowBounds") or {}
    if (b.get("Width") or 0)<240 or (b.get("Height") or 0)<160: continue
    name=(w.get("kCGWindowOwnerName") or "").replace("\t"," ")
    print("%s\t%s\t%s"%(w.get("kCGWindowNumber"), w.get("kCGWindowOwnerPID") or 0, name))']]

local seen = {}
local hold = {}

local function aeroIds()
    local ids = {}
    local out = hs.execute(
        string.format(
            "%q list-windows --all --format '%%{window-id}'",
            aerospace
        )
    ) or ""
    for id in out:gmatch("%d+") do
        ids[id] = true
    end
    return ids
end

local function surface(id, pid, name)
    local window = hs.window.get(tonumber(id))
    if window then
        window:unminimize()
        window:raise()
        window:focus()
    elseif pid and pid ~= "0" then
        hs.execute(
            string.format(
                "/usr/bin/osascript -e %q",
                string.format(
                    'tell application "System Events" to set frontmost of the first process whose unix id is %s to true',
                    pid
                )
            )
        )
    end
    hs.alert.show(
        (name ~= "" and name or "A window") .. " is not in a workspace",
        2.5
    )
end

local function scan()
    local raw = hs.execute(listCmd) or ""
    local aero
    local live = {}
    for line in raw:gmatch("[^\n]+") do
        local id, pid, name = line:match("^(%d+)\t(%d+)\t(.*)$")
        if id then
            live[id] = true
            if not seen[id] then
                if not aero then
                    aero = aeroIds()
                end
                if aero[id] then
                    seen[id] = true
                    hold[id] = nil
                else
                    hold[id] = (hold[id] or 0) + 1
                    if hold[id] >= 2 then
                        seen[id] = true
                        hold[id] = nil
                        surface(id, pid, name)
                    end
                end
            end
        end
    end
    for id in pairs(hold) do
        if not live[id] then
            hold[id] = nil
        end
    end
end

strayTimer = hs.timer.doEvery(1, scan)
scan()
