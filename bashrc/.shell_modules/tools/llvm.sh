# clangd on macOS.
#
# Homebrew's llvm formula is keg-only: it is deliberately not symlinked onto
# PATH because macOS already ships a clang and running two in parallel causes
# trouble. But clangd is the one tool in it this setup genuinely needs --
# nvim/lsp/clangd.lua runs `clangd` by name, and Xcode Command Line Tools do
# not provide one. Without this, C/C++ gets no language server at all on a Mac
# and the only symptom is that nothing works.
#
# Appended, never prepended: `clangd` exists only in the keg so it resolves
# either way, while `clang`/`cc`/`ld` stay Apple's, which is what the keg-only
# warning is actually about.
if command -v is_macos >/dev/null 2>&1 && is_macos; then
    for __llvm_bin in /opt/homebrew/opt/llvm/bin /usr/local/opt/llvm/bin; do
        if [ -d "$__llvm_bin" ]; then
            case ":$PATH:" in
            *":$__llvm_bin:"*) ;;
            *) export PATH="$PATH:$__llvm_bin" ;;
            esac
        fi
    done
    unset __llvm_bin
fi
