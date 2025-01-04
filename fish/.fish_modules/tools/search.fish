# Fish search

if command -v fd >/dev/null 2>&1
    alias fd='fd'
else
    alias fd='find . -type f -name'
end

function maliases
    rg -e "^alias.*$argv[1].*" ~/dotfiles/bashrc/.bashrc ~/dotfiles/bashrc/.shell_modules --no-ignore --hidden --glob "*.sh" --glob "*.bashrc"
end

function search
    if test (count $argv) -lt 1
        echo "Usage: search PATTERN [RG_ARGS...]"
        return 1
    end

    set -l pattern $argv[1]
    set -l extra_args $argv[2..-1]

    rg -l --hidden --no-ignore $pattern . $extra_args
end

function replace
    if test (count $argv) -lt 2
        echo "Usage: replace OLD_TEXT NEW_TEXT [RG_ARGS...]"
        echo "Note: Uses search PATTERN --null [RG_ARGS...] for finding files to replace in"
        return 1
    end

    set -l old $argv[1]
    set -l new $argv[2]
    set -l extra $argv[3..-1]

    # null seperated filenames passed to sed
    search $old $extra --null | xargs -0 sed -i "s|$old|$new|g"
end
