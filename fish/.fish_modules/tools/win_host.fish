function win_host
    set WIN_HOST $(grep nameserver /etc/resolv.conf | awk '{print $2}')
    echo "Windows is at $WIN_HOST"
end
