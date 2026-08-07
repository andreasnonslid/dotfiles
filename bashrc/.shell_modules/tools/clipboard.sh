# clip/paste -- clipboard abstraction.
#
# Dispatch is runtime, not install-time: a Linux box can be Wayland in one
# session and X11 in the next, so every call re-checks the environment
# rather than caching a choice made when this file was sourced.
#
#   clip   -- stdin -> clipboard
#   paste  -- clipboard -> stdout
#
# .bashrc exports $DOTFILES before sourcing anything under .shell_modules,
# so it's already set by the time this file loads.
__clipboard_dotfiles="${DOTFILES:-$HOME/dotfiles}"
if [ -r "$__clipboard_dotfiles/lib/os.sh" ]; then
    # shellcheck source=/dev/null
    . "$__clipboard_dotfiles/lib/os.sh"
fi
unset __clipboard_dotfiles

clip() {
    if command -v is_macos >/dev/null 2>&1 && is_macos; then
        pbcopy
    elif command -v is_wsl >/dev/null 2>&1 && is_wsl && command -v clip.exe >/dev/null 2>&1; then
        clip.exe
    elif [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
        wl-copy
    elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard
    else
        echo "clip: no clipboard tool available for this session" >&2
        return 1
    fi
}
wfn clip "Copy stdin to the system clipboard"

paste() {
    if command -v is_macos >/dev/null 2>&1 && is_macos; then
        pbpaste
    elif command -v is_wsl >/dev/null 2>&1 && is_wsl && command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -NoProfile -Command Get-Clipboard | tr -d '\r'
    elif [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-paste >/dev/null 2>&1; then
        wl-paste
    elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -o
    else
        echo "paste: no clipboard tool available for this session" >&2
        return 1
    fi
}
wfn paste "Print the system clipboard contents to stdout"
