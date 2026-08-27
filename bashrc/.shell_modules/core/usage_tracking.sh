# Usage tracking -- records which shortcuts actually get used, so the ~130
# aliases and functions in this repo can be pruned on evidence instead of
# memory.
#
# Records the FIRST WORD ONLY, never arguments. Arguments here routinely carry
# Jira ticket ids, ssh key names, hostnames and absolute paths; none of that is
# needed to answer "do I still use this alias?", and a shell history duplicated
# into a second file is a liability nobody asked for.
#
# One line per command, TSV: epoch <TAB> shell <TAB> command.
#
#   Opt out:      export DOTFILES_USAGE_TRACK=0
#   Move the log: export DOTFILES_USAGE_LOG=/some/path.tsv
#
# The log lives outside the repo by default. Writing it inside a git working
# tree would dirty `git status` on every command and put the pre-commit hook in
# a fight with the shell, which is a good way to end up disabling one of them.
#
# Read the results with: scripts/usage-report.sh

if [ "${DOTFILES_USAGE_TRACK:-1}" = "1" ]; then

    : "${DOTFILES_USAGE_LOG:=$HOME/.local/state/dotfiles/usage.tsv}"

    # Created once at source time, not per command.
    mkdir -p "${DOTFILES_USAGE_LOG%/*}" 2>/dev/null || true

    # Commands worth ignoring: bare paths (./x, /usr/bin/y) are not shortcuts,
    # and the tracking internals must never record themselves.
    __usage_record() {
        [ -n "${DOTFILES_USAGE_LOG:-}" ] || return 0

        __usage_line="$1"
        # Trim leading whitespace, then take everything up to the first space.
        __usage_line="${__usage_line#"${__usage_line%%[![:space:]]*}"}"
        __usage_cmd="${__usage_line%%[[:space:]]*}"

        case "$__usage_cmd" in
        "" | \#* | */* | __usage_* | *=*) return 0 ;;
        esac

        # $EPOCHSECONDS avoids forking date(1) on every single prompt.
        if [ -n "${EPOCHSECONDS:-}" ]; then
            __usage_now="$EPOCHSECONDS"
        else
            __usage_now="$(date +%s 2>/dev/null || echo 0)"
        fi

        printf '%s\t%s\t%s\n' \
            "$__usage_now" "${__usage_shell:-sh}" "$__usage_cmd" \
            >>"$DOTFILES_USAGE_LOG" 2>/dev/null || true
    }

    if [ -n "${ZSH_VERSION:-}" ]; then
        __usage_shell="zsh"
        # zmodload gives $EPOCHSECONDS; harmless if it is already loaded.
        zmodload zsh/datetime 2>/dev/null || true
        __usage_preexec() { __usage_record "$1"; }
        autoload -Uz add-zsh-hook 2>/dev/null && add-zsh-hook preexec __usage_preexec

    elif [ -n "${BASH_VERSION:-}" ]; then
        __usage_shell="bash"
        __usage_last=""
        # bash has no preexec, so the last history entry is read at the next
        # prompt instead. That means one entry per prompt: a compound line
        # (`a; b`) records only its first command. Fine for the question being
        # asked, and far cheaper than a DEBUG trap firing per pipeline element.
        __usage_prompt() {
            __usage_hist="$(HISTTIMEFORMAT='' history 1 2>/dev/null)"
            __usage_hist="${__usage_hist#"${__usage_hist%%[![:space:]]*}"}"
            __usage_num="${__usage_hist%%[[:space:]]*}"
            # Same history entry as last prompt means nothing new was run.
            [ "$__usage_num" = "$__usage_last" ] && return 0
            __usage_last="$__usage_num"
            __usage_record "${__usage_hist#*[[:space:]]}"
        }
        case "${PROMPT_COMMAND:-}" in
        *__usage_prompt*) ;;
        "") PROMPT_COMMAND="__usage_prompt" ;;
        *) PROMPT_COMMAND="__usage_prompt;${PROMPT_COMMAND}" ;;
        esac
    fi
fi
