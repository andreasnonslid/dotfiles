# Fish WSL cleanup function

function wsl_clean
    echo "Attempting WSL shutdown..."
    wsl --shutdown 2>/dev/null && echo "WSL has been cleaned and shut down." || echo "WSL shutdown failed."
end
