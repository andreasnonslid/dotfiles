# Function wrapper: makes functions discoverable via maliases with -h/--help support
#
# Usage: wfn <function_name> ["description"]
#   Registers a function so that:
#     - It appears in maliases search results
#     - Calling <function_name> -h prints the function source

__fn_wrapper() {
    local fn_name="$1"
    shift

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        local desc
        desc="$(__fn_desc "$fn_name")"
        if [[ -n "$desc" ]]; then
            echo "# $fn_name -- $desc"
        else
            echo "# $fn_name"
        fi
        if command -v bat >/dev/null 2>&1; then
            declare -f "$fn_name" | bat --language=bash --style=plain --paging=never
        else
            declare -f "$fn_name"
        fi
        return 0
    fi

    "$fn_name" "$@"
}

# Clean up aliases from previous source (supports reloadbash).
# Without this, re-sourcing a file containing both `rs() { ... }` and `wfn rs`
# would fail because bash expands the existing `rs` alias during parsing of `rs() {`.
# Uses -gA so the array stays global even when sourced from inside a function.
# `alias -p` is bash-only and errors under zsh; `alias -L` is zsh's equivalent
# and prints the identical "alias name='value'" form, so one sed handles both.
if [ -n "${ZSH_VERSION:-}" ]; then
    __fn_alias_dump="$(alias -L 2>/dev/null)"
else
    __fn_alias_dump="$(alias -p 2>/dev/null)"
fi
for __fn_key in $(printf '%s\n' "$__fn_alias_dump" | sed -n "s/^alias \([^=]*\)='__fn_wrapper .*/\1/p"); do
    unalias "$__fn_key" 2>/dev/null
done
unset __fn_key __fn_alias_dump __fn_descriptions 2>/dev/null
declare -gA __fn_descriptions

__fn_desc() {
    echo "${__fn_descriptions[$1]:-}"
}

wfn() {
    local fn_name="$1"
    local description="${2:-}"

    if [[ -n "$description" ]]; then
        __fn_descriptions["$fn_name"]="$description"
    fi

    # Expanding at definition time is required: every alias has to carry its
    # own function name, which is what the trailing "$fn_name" bakes in.
    # shellcheck disable=SC2139
    alias "$fn_name"='__fn_wrapper '"$fn_name"
}
