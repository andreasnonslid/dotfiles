# mise -- single activation line, shared by bash and zsh (M22).
#
# Replaces the pyenv and nvm init blocks that used to live in .bashrc.
# rustup/~/.cargo/env is left alone -- mise adds nothing there.
#
# tools/*.sh is sourced by both .bashrc and .zshrc from the same loop, so
# this detects which shell is running rather than shipping one copy per
# adapter, matching tools/clipboard.sh's runtime-dispatch approach.
if command -v mise >/dev/null 2>&1; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(mise activate zsh)"
    elif [ -n "${BASH_VERSION:-}" ]; then
        if command -v __cached_init >/dev/null 2>&1; then
            __cached_init mise mise activate bash
        else
            eval "$(mise activate bash)"
        fi
        # Stock activation runs `mise hook-env` on every prompt (~90 ms: the
        # binary is ~240 MB). cd already re-runs it (chpwd), so only re-run it
        # here when the directory changed some other way (zoxide uses builtin
        # cd) or after any `mise` command (use/install/... may change tools).
        if declare -F _mise_hook >/dev/null; then
            __MISE_LAST_PWD=$PWD
            _mise_hook_prompt_command() {
                local rc=$?
                if [[ ${__MISE_BASH_CHPWD_RAN:-0} != 1 && $PWD != "${__MISE_LAST_PWD-}" ]]; then
                    _mise_hook --reason precmd
                fi
                __MISE_LAST_PWD=$PWD
                __MISE_BASH_CHPWD_RAN=0
                unset __MISE_BASH_SKIP_FIRST_PROMPT
                return $rc
            }
            # Same as mise's own wrapper (shell/deactivate must be eval'd),
            # plus a forced hook-env run at the next prompt.
            mise() {
                local rc
                case "${1:-}" in
                deactivate | shell | sh)
                    eval "$(command mise "$@")"
                    rc=$?
                    ;;
                *)
                    command mise "$@"
                    rc=$?
                    ;;
                esac
                __MISE_LAST_PWD=
                return $rc
            }
        fi
    fi
fi
