# macOS Homebrew PATH wiring (M13).
#
# macos/install.sh evals brew shellenv for its own process only. This makes
# brew available in every interactive shell on darwin without touching Linux.
case "$(uname -s)" in
Darwin)
    case "$(uname -m)" in
    arm64) brew_prefix=/opt/homebrew ;;
    *) brew_prefix=/usr/local ;;
    esac
    if [ -x "$brew_prefix/bin/brew" ]; then
        eval "$("$brew_prefix/bin/brew" shellenv)"
    fi
    ;;
esac
