# Bash completion setup

# Enable programmable completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Load git completion and register completions for git aliases
if type __load_completion >/dev/null 2>&1; then
    __load_completion git >/dev/null 2>&1
fi

# Register git alias completions
if type __git_complete >/dev/null 2>&1; then
    __git_complete a git_add 2>/dev/null || true
    __git_complete aa git_add 2>/dev/null || true
    __git_complete au git_add 2>/dev/null || true
    __git_complete b git_branch 2>/dev/null || true
    __git_complete bb git_branch 2>/dev/null || true
    __git_complete bv git_branch 2>/dev/null || true
    __git_complete bd git_branch 2>/dev/null || true
    __git_complete bsu git_branch 2>/dev/null || true
    __git_complete ch git_checkout 2>/dev/null || true
    __git_complete cl git_clone 2>/dev/null || true
    __git_complete c git_commit 2>/dev/null || true
    __git_complete cm git_commit 2>/dev/null || true
    __git_complete ca git_commit 2>/dev/null || true
    __git_complete cf git_commit 2>/dev/null || true
    __git_complete d git_diff 2>/dev/null || true
    __git_complete dc git_diff 2>/dev/null || true
    __git_complete dh git_diff 2>/dev/null || true
    __git_complete dw git_diff 2>/dev/null || true
    __git_complete i git_init 2>/dev/null || true
    __git_complete lg git_log 2>/dev/null || true
    __git_complete lgu git_log 2>/dev/null || true
    __git_complete log git_log 2>/dev/null || true
    __git_complete logo git_log 2>/dev/null || true
    __git_complete m git_merge 2>/dev/null || true
    __git_complete ma git_merge 2>/dev/null || true
    __git_complete mc git_merge 2>/dev/null || true
    __git_complete pl git_pull 2>/dev/null || true
    __git_complete p git_push 2>/dev/null || true
    __git_complete r git_rebase 2>/dev/null || true
    __git_complete ri git_rebase 2>/dev/null || true
    __git_complete ref git_reflog 2>/dev/null || true
    __git_complete re git_remote 2>/dev/null || true
    __git_complete sh git_show 2>/dev/null || true
    __git_complete st git_stash 2>/dev/null || true
    __git_complete sp git_stash 2>/dev/null || true
    __git_complete stl git_stash 2>/dev/null || true
    __git_complete std git_stash 2>/dev/null || true
    __git_complete stc git_stash 2>/dev/null || true
    __git_complete stp git_stash 2>/dev/null || true
    __git_complete sta git_stash 2>/dev/null || true
    __git_complete s git_status 2>/dev/null || true
    __git_complete ss git_status 2>/dev/null || true
    __git_complete sub git_submodule 2>/dev/null || true
    __git_complete subi git_submodule 2>/dev/null || true
    __git_complete subu git_submodule 2>/dev/null || true
    __git_complete suba git_submodule 2>/dev/null || true
    __git_complete sw git_switch 2>/dev/null || true
    __git_complete t git_tag 2>/dev/null || true
    __git_complete ta git_tag 2>/dev/null || true
fi

# Custom completion functions
_gcmp() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local branches
    branches=$(git branch --format='%(refname:short)' 2>/dev/null)
    COMPREPLY=($(compgen -W "$branches" -- "$cur"))
}
complete -F _gcmp gcmp 2>/dev/null || true

_rs() {
    COMPREPLY=($(compgen -W "1 2 3 4 5" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -F _rs rs 2>/dev/null || true

_rh() {
    COMPREPLY=($(compgen -W "1 2 3 4 5" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -F _rh rh 2>/dev/null || true
