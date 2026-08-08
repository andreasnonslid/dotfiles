-- pretty.lua -- Data-driven multi-language formatter orchestrator
-- Usage: lua pretty.lua [-w|--write] [-l|--list] [-h|--help]
--   Also: nvim -l pretty.lua [-w|--write] [-l|--list]

local exclude = {
    "*/z.sh",
    -- pytest's own gitignored cache dir. Never mattered while
    -- executable_exists() silently skipped every formatter; now that it
    -- actually runs, check.sh's own pytest stage (which runs first) leaves
    -- this behind every time, and prettier picks up its README.md.
    "*/.pytest_cache/*",
}

local formatters = {
    {
        cmd = "shfmt",
        exts = { "sh", "bash", "zsh" },
        list = "-l",
        write = "-w",
    },
    {
        cmd = "stylua",
        exts = { "lua" },
        list = "--check",
        write = "",
    },
    {
        cmd = "black",
        exts = { "py" },
        list = "--check --quiet",
        write = "--quiet",
    },
    {
        cmd = "taplo format",
        exts = { "toml" },
        list = "--check",
        write = "",
    },
    {
        cmd = "clang-format",
        exts = { "c", "cpp", "h", "hpp", "java" },
        list = "--dry-run --Werror",
        write = "-i",
    },
    {
        cmd = "prettier",
        exts = { "js", "jsx", "ts", "tsx", "json", "md", "yaml", "yml" },
        list = "-l",
        write = "--write",
    },
}

local mode = "list"

local function usage()
    io.stderr:write("Usage: lua pretty.lua [-w|--write] [-l|--list]\n")
    io.stderr:write("  -w, --write   format files in place\n")
    io.stderr:write(
        "  -l, --list    list files that need formatting (default)\n"
    )
    os.exit(1)
end

for i = 1, #arg do
    local a = arg[i]
    if a == "-w" or a == "--write" then
        mode = "write"
    elseif a == "-l" or a == "--list" then
        mode = "list"
    elseif a == "-h" or a == "--help" then
        usage()
    else
        io.stderr:write("Unknown: " .. a .. "\n")
        usage()
    end
end

local function executable_exists(cmd)
    local bin = cmd:match("^(%S+)")
    local ok = os.execute("command -v " .. bin .. " >/dev/null 2>&1")
    -- Lua 5.1/LuaJIT (nvim -l) returns the raw status as a number, 0 on
    -- success; Lua 5.2+ (the standalone `lua` this repo's tooling uses)
    -- returns a boolean instead. Same dual check already used below for
    -- the formatter run itself -- this function just missed it.
    return ok == true or ok == 0
end

local function ext_pattern(exts)
    local parts = {}
    for _, ext in ipairs(exts) do
        parts[#parts + 1] = "-iname '*." .. ext .. "'"
    end
    return "\\( " .. table.concat(parts, " -o ") .. " \\)"
end

local failed = false

for _, fmt in ipairs(formatters) do
    if not executable_exists(fmt.cmd) then
        io.stderr:write("skip: " .. fmt.cmd .. " not found\n")
    else
        local flags = mode == "list" and fmt.list or fmt.write
        local cmd = fmt.cmd
        if flags ~= "" then
            cmd = cmd .. " " .. flags
        end

        local prune = "-path '*/.git/*' -prune"
        for _, pat in ipairs(exclude) do
            prune = prune .. " -o -path '" .. pat .. "' -prune"
        end

        local ok = os.execute(
            string.format(
                "find . %s -o -type f %s -print0 | xargs -0 %s",
                prune,
                ext_pattern(fmt.exts),
                cmd
            )
        )
        if ok ~= 0 and ok ~= true then
            failed = true
        end
    end
end

if failed then
    os.exit(1)
end
