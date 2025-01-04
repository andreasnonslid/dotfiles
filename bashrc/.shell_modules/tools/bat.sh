if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias batc='bat --paging=always'
fi
