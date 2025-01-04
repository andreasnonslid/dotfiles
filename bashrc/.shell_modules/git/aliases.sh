alias gs="git status --untracked-files=normal"
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gco="git checkout"
alias gsb="git switch -c"
alias gsw="git switch"
alias gp="git push"
alias gpl="git pull"
alias gr="git rebase"
alias grs="git restore"
alias gb="git branch"
alias gf="git fetch"
alias gds="git diff --staged"
alias gfp="git fetch --prune"
alias gca="git commit --amend --no-edit"
alias gl="git log --oneline --graph --all --decorate"

alias grsall="git restore ."
alias grsstaged="git restore --staged"
alias glast="git log -p -1"
alias gundo="git reset --soft HEAD~1"
alias gprune='git fetch -p && git branch --merged | grep -v "\*\|main\|master" | xargs -n 1 git branch -d'

gcmp() {
    git log --oneline --graph "$1..$2"
}

gsquash() {
    git rebase -i "$(git rev-list --max-parents=0 HEAD)"
}

gxcl() {
    git reset --hard &&
        git clean -ffdx &&
        git submodule sync --recursive &&
        git submodule update --init --recursive --force &&
        git submodule foreach --recursive git clean -ffdx &&
        git checkout --force
}

gxclFULL() {
    git reset --hard --recurse-submodules &&
        git lfs fetch --all &&
        git lfs prune &&
        git add --renormalize . &&
        git stash --include-untracked &&
        git clean -ffdx &&
        git reflog expire --all --expire='2.weeks.ago' --expire-unreachable='now' &&
        git gc --prune=now &&
        git submodule sync --recursive &&
        git submodule update --init --recursive --force &&
        git submodule foreach --recursive git clean -ffdx &&
        git checkout --force
}
