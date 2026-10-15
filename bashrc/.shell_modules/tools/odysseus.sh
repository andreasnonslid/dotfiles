# Toggle the Odysseus web UI: run `odysseus` to start it in the background,
# run it again to stop it.
# Machine-specific: define nothing unless Odysseus is installed here.
[ -d "$HOME/dev/odysseus" ] || return 0

ODYSSEUS_DIR="$HOME/dev/odysseus"
ODYSSEUS_PORT=7000
ODYSSEUS_PID_FILE="$HOME/.cache/odysseus.pid"
ODYSSEUS_LOG="$HOME/.cache/odysseus.log"

odysseus() {
    mkdir -p "$HOME/.cache"
    if [ -f "$ODYSSEUS_PID_FILE" ] && kill -0 "$(cat "$ODYSSEUS_PID_FILE")" 2>/dev/null; then
        local pid
        pid=$(cat "$ODYSSEUS_PID_FILE")
        # Started via setsid, so the pid is the process group leader: kill the whole group.
        kill -- "-$pid" 2>/dev/null || kill "$pid"
        rm -f "$ODYSSEUS_PID_FILE"
        echo "Odysseus stopped"
        return
    fi

    (
        cd "$ODYSSEUS_DIR" || exit 1
        setsid "$ODYSSEUS_DIR/venv/bin/python" -m uvicorn app:app \
            --host 127.0.0.1 --port "$ODYSSEUS_PORT" \
            >"$ODYSSEUS_LOG" 2>&1 </dev/null &
        echo $! >"$ODYSSEUS_PID_FILE"
    )
    local url="http://localhost:$ODYSSEUS_PORT" i
    echo "Odysseus starting..."
    for i in $(seq 1 60); do
        if curl -s -o /dev/null "$url"; then
            echo "Odysseus is up, open: $url"
            return
        fi
        sleep 0.5
    done
    echo "Odysseus not answering yet, check the log: $ODYSSEUS_LOG (will be at $url)"
}
