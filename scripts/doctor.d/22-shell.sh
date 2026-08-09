#!/usr/bin/env bash
# scripts/doctor.d/22-shell.sh -- shell health: login shell, module
# sourcing, alias/function inventory, tool initialisation, clip/paste
# round-trip (D04).
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/
# doctor_warn/doctor_fail, sets $root and $current_section, and has
# lib/os.sh sourced. This file must not be run standalone.
#
# .bashrc/.zshrc source ~20 files under .shell_modules in a loop; a file
# that errors out partway still leaves the shell running, just silently
# missing whatever the rest of that file (and anything after it in the
# loop) would have defined -- a failure mode that's easy to live with for
# weeks. This checks both bash and zsh, whichever are installed, rather
# than only the current OS's intended login shell: macOS keeps .bashrc
# symlinked alongside .zshrc (symlink.py has no darwin exclusion for it),
# so bash is worth checking there too, and a Linux box may have zsh
# installed even though bash stays the login shell.
#
# shellcheck disable=SC2154  # $root: set by scripts/doctor.sh before sourcing.

section="shell"

modules_dir="$HOME/.shell_modules"

if [ ! -d "$modules_dir" ]; then
    doctor_warn "$section" "$modules_dir not found" \
        "Bootstrap didn't run, or ran partially -- run ./bootstrap.sh."
else
    # ---- login shell ---------------------------------------------------
    # zsh is the intended login shell on darwin (M08); bash stays it
    # everywhere else, WSL included.
    expected_shell="bash"
    is_macos && expected_shell="zsh"

    login_shell=""
    if command -v getent >/dev/null 2>&1; then
        login_shell="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)"
    elif is_macos && command -v dscl >/dev/null 2>&1; then
        login_shell="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}')"
    fi
    [ -z "$login_shell" ] && login_shell="${SHELL:-}"

    if [ -z "$login_shell" ]; then
        doctor_warn "$section" "Could not determine the login shell" \
            "Neither getent, dscl nor \$SHELL gave an answer."
    elif [ "$(basename "$login_shell")" = "$expected_shell" ]; then
        doctor_pass "$section" "Login shell is $login_shell (expected $expected_shell)"
    else
        doctor_fail "$section" "Login shell is $login_shell, expected $expected_shell" \
            "Run 'chsh -s \$(command -v $expected_shell)', then open a new terminal."
    fi

    # ---- module sourcing + alias/function inventory ---------------------
    # The committed floor (scripts/shell-inventory.expected) is a subset
    # check, not an exact match: tools/{bat,eza,agent}.sh gate their
    # aliases behind `command -v <tool>`, so the live inventory legitimately
    # grows on a machine that has them installed. What must never happen is
    # an expected name going missing -- that's a module failing to load.
    expected_file="$root/scripts/shell-inventory.expected"
    expected_aliases=()
    expected_funcs=()
    if [ -f "$expected_file" ]; then
        while read -r kind name; do
            case "$kind" in
            alias) expected_aliases+=("$name") ;;
            func) expected_funcs+=("$name") ;;
            esac
        done < <(grep -vE '^#|^$' "$expected_file")
    else
        doctor_warn "$section" "$expected_file not found" \
            "Regenerate with scripts/gen-shell-inventory.sh > scripts/shell-inventory.expected."
    fi

    check_shell_flavor() {
        local shell_bin="$1" adapter="$2"

        if ! command -v "$shell_bin" >/dev/null 2>&1; then
            doctor_warn "$section" "$shell_bin not installed -- skipping its module check" \
                "Install $shell_bin to exercise $adapter/*.sh and confirm it loads cleanly."
            return
        fi

        local probe err_file out rc
        probe="$(mktemp)"
        err_file="$(mktemp)"

        {
            printf 'export DOTFILES=%q\n' "$root"
            printf 'modules_dir=%q\n' "$modules_dir"
            printf 'adapter=%q\n' "$adapter"
            cat <<'PROBE_BODY'
for group in core git tools "$adapter"; do
    dir="$modules_dir/$group"
    [ -d "$dir" ] || continue
    for f in "$dir"/*.sh; do
        [ -e "$f" ] || continue
        if ! source "$f"; then
            echo "SOURCE_FAILED:$f"
            exit 2
        fi
    done
done
echo "===ALIASES==="
PROBE_BODY
            if [ "$shell_bin" = zsh ]; then
                # shellcheck disable=SC2016  # literal zsh syntax written into the probe file, not expanded here.
                echo 'print -l -- ${(k)aliases} | sort -u'
                echo 'echo "===FUNCS==="'
                # shellcheck disable=SC2016  # literal zsh syntax written into the probe file, not expanded here.
                echo 'print -l -- ${(k)functions} | sort -u'
            else
                echo 'compgen -a | sort -u'
                echo 'echo "===FUNCS==="'
                echo 'compgen -A function | sort -u'
            fi
        } >"$probe"

        # --norc/--no-rcs plus -i: interactive so bash's `bind`/readline
        # setup in bash/settings.sh doesn't warn about a disabled line
        # editor, but without the caller's real rc files so this reflects
        # only what .shell_modules itself defines.
        if [ "$shell_bin" = zsh ]; then
            out="$(zsh --no-rcs -i "$probe" 2>"$err_file")"
        else
            out="$(bash --norc -i "$probe" 2>"$err_file")"
        fi
        rc=$?
        rm -f "$probe"

        if [ "$rc" -eq 2 ]; then
            local failed_file
            failed_file="$(printf '%s\n' "$out" | grep '^SOURCE_FAILED:' | head -1 | cut -d: -f2-)"
            doctor_fail "$section" "$shell_bin: $failed_file failed to source" \
                "$(tail -3 "$err_file" | tr '\n' ' ')"
        elif [ "$rc" -ne 0 ]; then
            doctor_fail "$section" "$shell_bin: module sourcing exited $rc" \
                "$(tail -3 "$err_file" | tr '\n' ' ')"
        else
            doctor_pass "$section" "$shell_bin: all .shell_modules files sourced cleanly"

            if [ -s "$err_file" ]; then
                doctor_warn "$section" "$shell_bin: sourcing produced stderr output despite exiting 0" \
                    "$(tail -3 "$err_file" | tr '\n' ' ')"
            fi

            local actual_aliases actual_funcs missing=""
            actual_aliases="$(printf '%s\n' "$out" | sed -n '/^===ALIASES===$/,/^===FUNCS===$/{//!p;}')"
            actual_funcs="$(printf '%s\n' "$out" | sed -n '/^===FUNCS===$/,$p' | sed 1d)"

            for name in "${expected_aliases[@]}"; do
                grep -qxF -- "$name" <<<"$actual_aliases" || missing="${missing}${missing:+, }alias:$name"
            done
            for name in "${expected_funcs[@]}"; do
                grep -qxF -- "$name" <<<"$actual_funcs" || missing="${missing}${missing:+, }func:$name"
            done

            if [ -n "$missing" ]; then
                doctor_fail "$section" "$shell_bin: expected alias/function(s) missing after sourcing: $missing" \
                    "A .shell_modules file likely errored partway through, or was removed from the source loop -- compare against $expected_file."
            else
                doctor_pass "$section" "$shell_bin: alias/function inventory matches the committed floor (${#expected_aliases[@]} aliases, ${#expected_funcs[@]} functions)"
            fi
        fi

        rm -f "$err_file"
    }

    check_shell_flavor bash bash
    check_shell_flavor zsh zsh
    unset -f check_shell_flavor

    # ---- starship / zoxide / mise initialisation -------------------------
    # "binary present" is D03's job; this confirms the init subcommand
    # itself succeeds and actually emits something to eval, independent of
    # whether .bashrc/.zshrc wires it in yet (mise isn't wired into .bashrc
    # until M22 lands).
    check_tool_init() {
        local tool="$1" subcmd="$2"
        if ! command -v "$tool" >/dev/null 2>&1; then
            doctor_warn "$section" "$tool not installed -- skipping init check" \
                "Expected until $tool is installed (Brewfile/mise.toml)."
            return
        fi
        local init_out
        if init_out="$(eval "$subcmd" 2>&1)" && [ -n "$init_out" ]; then
            doctor_pass "$section" "$tool init emits shell setup"
        else
            doctor_fail "$section" "$tool init produced no output or failed" \
                "Run '$subcmd' by hand to see what it printed/errored."
        fi
    }

    check_tool_init starship "starship init bash"
    check_tool_init zoxide "zoxide init bash"
    check_tool_init mise "mise activate bash"
    unset -f check_tool_init

    # ---- clip/paste round-trip --------------------------------------------
    # 20-clipboard.sh already checks the underlying tool is on PATH; this
    # checks the abstraction actually round-trips a value through it, which
    # a present-but-misbehaving tool (e.g. clipboard daemon not running)
    # wouldn't catch.
    have_clipboard=0
    if is_macos; then
        command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1 && have_clipboard=1
    elif is_wsl; then
        command -v clip.exe >/dev/null 2>&1 && have_clipboard=1
    elif [ -n "${WAYLAND_DISPLAY:-}" ]; then
        command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1 && have_clipboard=1
    elif [ -n "${DISPLAY:-}" ]; then
        command -v xclip >/dev/null 2>&1 && have_clipboard=1
    fi

    if [ "$have_clipboard" -ne 1 ]; then
        doctor_warn "$section" "No usable clipboard tool/session for this check" \
            "See the clipboard section above for what's missing."
    else
        marker="doctor-clip-roundtrip-$$"
        roundtrip="$(
            bash --norc -c '
                export DOTFILES="$1"
                for f in "$2"/tools/clipboard.sh; do source "$f"; done
                printf %s "$3" | clip
                paste
            ' _ "$root" "$modules_dir" "$marker" 2>/dev/null
        )"
        if [ "$roundtrip" = "$marker" ]; then
            doctor_pass "$section" "clip | paste round-trips a known value"
        else
            doctor_fail "$section" "clip | paste did not round-trip (got '$roundtrip')" \
                "Run 'echo hi | clip && paste' by hand to see where it diverges."
        fi
    fi
fi
