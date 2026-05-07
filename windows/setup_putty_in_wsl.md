# WSL UART terminal via plink.exe

Same pattern as the openocd wrapper — call the Windows binary from WSL, thin shim on PATH.

## Setup

```bash
cat > ~/tools/scripts/uart << 'EOF'
#!/bin/bash
PORT="${1:-COM11}"
BAUD="${2:-115200}"
pkill -f "plink.exe.*-serial" 2>/dev/null
exec "/mnt/c/Program Files/PuTTY/plink.exe" -serial "$PORT" -sercfg "$BAUD,8,n,1,N"
EOF
chmod +x ~/tools/scripts/uart

cat > ~/.local/bin/uart << 'EOF'
#!/bin/bash
exec ~/tools/scripts/uart "$@"
EOF
chmod +x ~/.local/bin/uart
```

## Usage

```bash
uart              # COM11 @ 115200 (defaults)
uart COM3         # different port
uart COM3 9600    # different port + baud
```

- Runs inline in your WSL terminal
- Kills any existing session on launch
- `ctrl-c` to quit
