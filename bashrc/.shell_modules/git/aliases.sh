# Git aliases - Ultra-short single-letter aliases

# add
alias a='git add'
alias aa='a --all'
alias au='a --update'

# branch
alias b='git branch'
alias bb='b --all'
alias bv='b -vv'
alias bd='b -d'
alias bsu='b --set-upstream-to'

# fetch
alias f="git fetch"

# checkout
alias ch='git checkout'

# clone
alias cl='git clone'

# commit
alias c='git commit'
alias cm='git commit -m'
alias ca='c --amend'
alias cf='c --fixup'

# diff
alias d='git diff'
alias dc='git diff --cached'
alias dh='d HEAD'
alias dw='d --word-diff'

# init
alias i='git init'

# log
alias lg='git log --graph --oneline --decorate --all'
alias lgu='git log --graph --oneline @{u}..HEAD'
alias log='git log --pretty=format:"%h %ad %s" --date=short --all'
alias logo='git log --oneline'

# merge
alias m='git merge'
alias ma='m --abort'
alias mc='m --continue'

# pull
alias pl='git pull'

# push
alias p='git push'
alias pf='git push --force-with-lease'

# rebase
alias r='git rebase'
alias ri='git rebase -i'
alias rom='r origin/master'
alias romain='r origin/main'
alias riom='ri origin/master'
alias riomain='ri origin/main'

# reflog
alias ref='git reflog'

# remote
alias re='git remote'

# reset functions
__gr-reset() {
    local mode="$1"        # soft|hard
    local target="${2:-1}" # N commits or ref, default 1
    git reset --"$mode" "HEAD~$target"
}

rs() {
    # soft-reset HEAD~N (default 1)
    __gr-reset soft "$@"
}

rh() {
    # hard-reset HEAD~N (default 1)
    __gr-reset hard "$@"
}

__gr-upstream-ref() {
    echo "origin/$(git branch --show-current)"
}

rsu() {
    # soft-reset to upstream
    git reset --soft "$(__gr-upstream-ref)"
}

rhu() {
    # hard-reset to upstream
    git reset --hard "$(__gr-upstream-ref)"
}

# show
alias sh='git show'

# stash
alias st='git stash'
alias sp='st pop'
alias stl='st list'
alias std='st drop'
alias stc='st clear'
alias stp='st push'
alias sta='st apply'

# status
alias s='git status'
alias ss='git status --short'

# submodule
alias sub='git submodule'
alias subi='sub init'
alias subu='sub update'
alias suba='sub add'

# switch
alias sw='git switch'

# tag
alias t='git tag'
alias ta='t -a'

# xtras
aac() {
    # add all and commit
    aa
    local msg="$*"
    c -m "$msg"
}

commit_types() {
    # Print Conventional Commit types fast
    local kw='\033[0;36m'   # cyan
    local full='\033[0;33m' # yellow
    local info='\033[0;37m' # white
    local rst='\033[0m'     # reset

    local types=(
        'feat        |Features|A new feature'
        'fix         |Bug Fixes|A bug fix'
        'docs        |Documentation|Documentation-only changes'
        'style       |Styles|Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)'
        'refactor    |Code Refactoring|A code change that neither fixes a bug nor adds a feature'
        'perf        |Performance Improvements|A code change that improves performance'
        'test        |Tests|Adding missing tests or correcting existing tests'
        'build       |Builds|Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)'
        'ci          |Continuous Integrations|Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)'
        'chore       |Chores|Other changes that do not modify src or test files'
        'revert      |Reverts|Reverts a previous commit'
    )

    for spec in "${types[@]}"; do
        IFS='|' read -r key full_name info_text <<<"$spec"
        echo -e "${kw}${key}${rst} ${full}${full_name}${rst}"
        echo -e "${info}${info_text}${rst}"
        echo
    done
}

gcmp() {
    git log --oneline --graph "$1..$2"
}

gsquash() {
    git rebase -i "$(git rev-list --max-parents=0 HEAD)"
}

___anh___wait_for_locks() {
    local max_wait=10
    local bar_length=20
    local check_interval=500
    local waited=0
    local max_wait_ms=$((max_wait * 1000))

    find .git -name "*.lock" -type f -delete 2>/dev/null || true

    if [ ! -f .git/index.lock ] && ! find .git -name "*.lock" -type f 2>/dev/null | grep -q .; then
        return 0
    fi

    echo "Waiting for git locks to clear."
    echo "Timeout: ${max_wait}s"

    while [ $waited -lt $max_wait_ms ]; do
        find .git -name "*.lock" -type f -delete 2>/dev/null || true

        if [ -f .git/index.lock ] || find .git -name "*.lock" -type f 2>/dev/null | grep -q .; then
            local filled=$(((waited * bar_length) / max_wait_ms))
            local bar="|"
            local i=0
            while [ $i -lt $filled ]; do
                bar="${bar}*"
                i=$((i + 1))
            done
            while [ $i -lt $bar_length ]; do
                bar="${bar}-"
                i=$((i + 1))
            done
            bar="${bar}|"

            printf "\r%s" "$bar"
            sleep 0.5
            waited=$((waited + check_interval))
        else
            printf "\n"
            break
        fi
    done

    find .git -name "*.lock" -type f -delete 2>/dev/null || true
}

gxcl() {
    ___anh___wait_for_locks
    git reset --hard &&
        git clean -ffdx &&
        git submodule sync --recursive &&
        ___anh___wait_for_locks
    git submodule update --init --recursive --force &&
        ___anh___wait_for_locks
    git submodule foreach --recursive 'git reset --hard HEAD && git clean -ffdx' &&
        git checkout --force
}

gxclfull() {
    ___anh___wait_for_locks
    git reset --hard &&
        git lfs fetch --all &&
        git lfs prune &&
        git add --renormalize . &&
        git stash --include-untracked &&
        git clean -ffdx &&
        git reflog expire --all --expire='2.weeks.ago' --expire-unreachable='now' &&
        git gc --prune=now &&
        ___anh___wait_for_locks
    git submodule deinit --force --all &&
        git submodule sync --recursive &&
        ___anh___wait_for_locks
    git submodule update --init --recursive --force &&
        ___anh___wait_for_locks
    git submodule foreach --recursive 'git reset --hard HEAD && git clean -ffdx' &&
        git checkout --force
}

gxclreset() {
    ___anh___wait_for_locks
    git reset --hard &&
        git clean -ffdx &&
        git submodule sync --recursive &&
        ___anh___wait_for_locks
    git submodule update --init --recursive --force &&
        ___anh___wait_for_locks
    git submodule foreach --recursive 'git fetch --all && git reset --hard origin/$(git rev-parse --abbrev-ref HEAD) && git clean -ffdx' &&
        git checkout --force
}
