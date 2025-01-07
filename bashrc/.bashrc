# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# Source core settings first
for config_file in ~/.shell_modules/core/*.sh; do
    source "$config_file"
done

# Source git configuration
for config_file in ~/.shell_modules/git/*.sh; do
    source "$config_file"
done

# Source tool configurations
for config_file in ~/.shell_modules/tools/*.sh; do
    source "$config_file"
done

# Source any remaining scripts
# for config_file in ~/.shell_modules/scripts/*.sh; do
#     source "$config_file"
# done

# Initialize zoxide if available
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# Pyenv initialization
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# SHELL PROMPT
# Initial values
last_exit_status="✔ "
exit_status_color="$LIGHT_GREEN"
git_info=""
jobs_count=""

# Function to get the return value of the last command
update_exit_status() {
    if [[ $? == 0 ]]; then
        last_exit_status="✔ " # Green color for success
        exit_status_color="$LIGHT_GREEN"
    else
        last_exit_status="✘ " # Red color for failure
        exit_status_color="$LIGHT_RED"
    fi
}

# Function to get git info
parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

# This function updates the prompt.
update_git_info() {
    local branch
    branch=$(parse_git_branch)
    if [[ -n $branch ]]; then
        git_info="\[$YELLOW\]➜  \[$LIGHT_YELLOW\]$branch"
        curBranch=$branch
    else
        git_info=""
        curBranch=$branch
    fi
}

# Function to get count of background jobs
update_jobs_count() {
    local count=$(jobs -p | wc -l)
    if [[ $count -gt 0 ]]; then
        jobs_count=" [$count]"
    else
        jobs_count=""
    fi
}

# Set the prompt
setPS1() {
    PS1="\[$exit_status_color\]$last_exit_status \[$LIGHT_BLUE\]\w $git_info \[$CYAN\]🕒 \t\n\[$WHITE\]❯ "
}

# Main function which does everything in order
updateStatusLine() {
    update_exit_status
    update_git_info
    update_jobs_count
    setPS1
}

# The commands which are run every time a command is entered in the shell
PROMPT_COMMAND="updateStatusLine"

# Optional: Use Starship prompt instead of custom prompt
# Uncomment the following lines to enable Starship:
# if command -v starship >/dev/null 2>&1; then
#     eval "$(starship init bash)"
#     # Disable custom prompt when using Starship
#     unset PROMPT_COMMAND
# fi

# Helpful aliases
alias cheat="curl cheat.sh/"
alias help="tldr"

# PATH settings
export PATH="$HOME/.cargo/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

export PATH="/opt/nvim-linux-x86_64/bin:$PATH"

# Call Fish for interactive shells
# if [[ $- == *i* ]]; then
#     if command -v fish >/dev/null 2>&1; then
#         exec fish
#     fi
# fi

. "$HOME/.cargo/env"

export STM32_PRG_PATH=/home/anh/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin

# Optional: Start Zellij on interactive shells
# Uncomment the following lines to enable Zellij auto-start:
if [[ $- == *i* ]]; then
    if [ -z "$ZELLIJ" ] && [ -z "$TMUX" ]; then
        if command -v zellij >/dev/null 2>&1; then
            zellij
        fi
    fi
fi

