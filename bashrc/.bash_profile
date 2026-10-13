# macOS login bash reads .bash_profile first. Delegate to .profile, which
# sources the full interactive config in .bashrc.
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
