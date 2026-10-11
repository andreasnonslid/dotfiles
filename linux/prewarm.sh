#!/bin/sh
# Read the desktop's binaries, libraries and caches into the page cache while the login screen waits.
# Reads only root-owned system paths (+ fontconfig caches); never executes or writes anything.
# Installed root-owned at /usr/local/libexec/dotfiles-prewarm, run once per boot at idle priority.
bins="sway swaybg swaylock swayidle waybar alacritty mako fuzzel squeekboard nm-applet \
blueman-applet nvim lisgd brightnessctl grim slurp wl-copy swaymsg notify-send fc-match"
{
    for b in $bins; do
        p=/usr/bin/$b
        [ -x "$p" ] || continue
        echo "$p"
        ldd "$p" 2>/dev/null | awk '/=> \//{print $3} /^\t\//{print $1}'
    done
    ls /usr/lib/x86_64-linux-gnu/dri/*.so 2>/dev/null
    ls /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/*/loaders/*.so 2>/dev/null
    ls /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/*/loaders.cache 2>/dev/null
    ls /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/Adwaita/icon-theme.cache 2>/dev/null
    ls /usr/share/glib-2.0/schemas/gschemas.compiled 2>/dev/null
    ls /var/cache/fontconfig/* /home/*/.cache/fontconfig/* 2>/dev/null
    ls /home/*/.local/share/fonts/*.ttf 2>/dev/null
} | sort -u | while read -r f; do
    [ -f "$f" ] && cat "$f" > /dev/null 2>&1
done
exit 0
