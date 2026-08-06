# lib/os.sh -- OS and architecture detection helpers.
#
# Pure POSIX sh: sourceable from bash, zsh and .profile. Sourcing this file
# only defines functions -- no PATH edits, no output, no other side effects.
#
# shellcheck shell=sh

# detect_os: print "darwin", "linux", "windows" or "unknown".
detect_os() {
    case "$(uname -s)" in
    Darwin)
        echo darwin
        ;;
    Linux)
        echo linux
        ;;
    CYGWIN* | MINGW* | MSYS*)
        echo windows
        ;;
    *)
        echo unknown
        ;;
    esac
}

# detect_arch: print "arm64", "x86_64" or the raw `uname -m` value for
# anything else (so later checks can flag Rosetta/x86 emulation on Apple
# Silicon by comparing this against the kernel's own reported arch).
detect_arch() {
    case "$(uname -m)" in
    arm64 | aarch64)
        echo arm64
        ;;
    x86_64 | amd64)
        echo x86_64
        ;;
    *)
        uname -m
        ;;
    esac
}

is_macos() {
    [ "$(detect_os)" = "darwin" ]
}

is_linux() {
    [ "$(detect_os)" = "linux" ]
}

# is_wsl: true only inside WSL. WSL's Linux kernel identifies itself in
# /proc/version (e.g. "Microsoft" for WSL1, "microsoft-standard" for WSL2);
# native Linux and macOS never match, so this is false there.
is_wsl() {
    is_linux || return 1
    [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null
}
