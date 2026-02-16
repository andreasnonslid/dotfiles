# Shutdown WSL (run from Windows to reclaim memory). No-op when wsl command unavailable.
wsl_clean() {
    if ! command -v wsl &>/dev/null; then
        echo "wsl_clean: wsl command not found (not on Windows or WSL not installed)."
        return 0
    fi
    echo "Attempting WSL shutdown..."
    if wsl --shutdown 2>/dev/null; then
        echo "WSL has been cleaned and shut down."
    else
        echo "WSL shutdown failed."
        return 1
    fi
}
wfn wsl_clean "Shutdown WSL to reclaim memory"
