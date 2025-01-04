# add
alias a='git add'
alias aa='a --all'
alias au='a --update'
complete -c a -w git-add
complete -c aa -w git-add
complete -c au -w git-add

# branch
alias b='git branch'
alias bb='b --all'
alias bv='b -vv'
alias bd='b -d'
alias bsu='b --set-upstream-to'
complete -c b -w git-branch
complete -c bb -w git-branch
complete -c bv -w git-branch
complete -c bd -w git-branch
complete -c bsu -w git-branch

# checkout
alias ch='git checkout'
complete -c ch -w git-checkout

# clone
alias cl='git clone'
complete -c cl -w git-clone

# commit
alias c='git commit'
alias cm='git commit -m'
alias ca='c --amend'
alias cf='c --fixup'
complete -c c -w git-commit
complete -c cm -w git-commit
complete -c ca -w git-commit
complete -c cf -w git-commit

# diff
alias d='git diff'
alias dc='git diff --cached'
alias dh='d HEAD'
alias dw='d --word-diff'
complete -c d -w git-diff
complete -c dc -w git-diff
complete -c dh -w git-diff
complete -c dw -w git-diff

# init
alias i='git init'
complete -c i -w git-init

# log
alias lg='git log --graph --oneline --decorate --all'
alias lgu='git log --graph --oneline @{u}..HEAD'
alias log='git log --pretty=format:"%h %ad %s" --date=short --all'
alias logo='git log --oneline'
complete -c lg -w git-log
complete -c lgu -w git-log
complete -c log -w git-log
complete -c logo -w git-log

# merge
alias m='git merge'
alias ma='m --abort'
alias mc='m --continue'
complete -c m -w git-merge
complete -c ma -w git-merge
complete -c mc -w git-merge

# pull
alias pl='git pull'
complete -c pl -w git-pull

# push
alias p='git push'
complete -c p -w git-push

# rebase
alias r='git rebase'
alias ri='git rebase -i'
complete -c r -w git-rebase
complete -c ri -w git-rebase

# reflog
alias ref='git reflog'
complete -c ref -w git-reflog

# remote
alias re='git remote'
complete -c re -w git-remote

# reset
function __gr-reset --description "git reset wrapper"
    set -l mode $argv[1]      # soft|hard
    set -l target $argv[2]    # N commits or ref
    test -z "$target"; and set target 1
    git reset --$mode "HEAD~$target"
end
function rs --description "soft-reset HEAD~N (default 1)"
    __gr-reset soft $argv[1]
end
function rh --description "hard-reset HEAD~N (default 1)"
    __gr-reset hard $argv[1]
end
function __gr-upstream-ref
    echo origin/(git branch --show-current)
end
function rsu --description "soft-reset to upstream"
    git reset --soft (__gr-upstream-ref)
end
function rhu --description "hard-reset to upstream"
    git reset --hard (__gr-upstream-ref)
end
complete -c rs  -d "soft reset HEAD~N"  -a "1 2 3 4 5"
complete -c rh  -d "hard reset HEAD~N"  -a "1 2 3 4 5"
complete -c rsu -d "soft reset to upstream"
complete -c rhu -d "hard reset to upstream"

# show
alias sh='git show'
complete -c sh -w git-show

# stash
alias st='git stash'
alias sp='st pop'
alias stl='st list'
alias std='st drop'
alias stc='st clear'
alias stp='st push'
alias sta='st apply'
complete -c st -w git-stash
complete -c sp -w git-stash
complete -c stl -w git-stash
complete -c std -w git-stash
complete -c stc -w git-stash
complete -c stp -w git-stash
complete -c sta -w git-stash

# status
alias s='git status'
alias ss='git status --short'
complete -c s -w git-status
complete -c ss -w git-status

# submodule
alias sub='git submodule'
alias subi='sub init'
alias subu='sub update'
alias suba='sub add'
complete -c sub -w git-submodule
complete -c subi -w git-submodule
complete -c subu -w git-submodule
complete -c suba -w git-submodule

# switch
alias sw="git switch"
complete -c sw -w git-switch

# tag
alias t="git tag"
alias ta="t -a"
complete -c t -w git-tag
complete -c ta -w git-tag

# xtras
function aac
    aa
    set msg (string join ' ' -- $argv)
    c -m "$msg"
end

function commit_types --description 'Print Conventional Commit types fast'
    # colour helpers
    set -l kw   (set_color cyan)
    set -l full (set_color yellow)
    set -l info (set_color white)
    set -l rst  (set_color normal)

    for spec in \
        'feat        |Features|A new feature' \
        'fix         |Bug Fixes|A bug fix' \
        'docs        |Documentation|Documentation-only changes' \
        'style       |Styles|Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)' \
        'refactor    |Code Refactoring|A code change that neither fixes a bug nor adds a feature' \
        'perf        |Performance Improvements|A code change that improves performance' \
        'test        |Tests|Adding missing tests or correcting existing tests' \
        'build       |Builds|Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)' \
        'ci          |Continuous Integrations|Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)' \
        'chore       |Chores|Other changes that do not modify src or test files' \
        'revert      |Reverts|Reverts a previous commit'
        set -l parts (string split '|' $spec)   # key|full|info
        echo -n $kw$parts[1]$rst' '
        echo $full$parts[2]$rst
        echo $info$parts[3]$rst
        echo
    end
end

complete -c gcmp -a "(git branch --format='%(refname:short)')" -d "Git branch"

alias gsquash="git rebase -i (git rev-list --max-parents=0 HEAD)"

alias gxcl="git reset --hard && git clean -ffdx && git submodule sync
--recursive && git submodule update --init --recursive --force && git submodule
foreach --recursive git clean -ffdx && git checkout --force"

alias gxclFULL="git reset --hard --recurse-submodules && git lfs fetch --all &&
git lfs prune && git add --renormalize . && git stash --include-untracked && git
clean -ffdx && git reflog expire --all --expire='2.weeks.ago'
--expire-unreachable='now' && git gc --prune=now && git submodule sync
--recursive && git submodule update --init --recursive --force && git submodule
foreach --recursive git clean -ffdx && git checkout --force"
