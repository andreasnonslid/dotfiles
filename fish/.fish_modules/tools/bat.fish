# Fish bat aliases

if command -v bat >/dev/null 2>&1
    alias cat='bat --paging=never'
    alias batc='bat --paging=always'
end
