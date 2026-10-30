#!/bin/sh
export PLAN9="/usr/local/plan9"
export PATH="$PLAN9/bin:$PATH"

# Default to rc when no command is given (matches the image CMD).
if [ $# -eq 0 ]; then
    set -- rc
fi

# Check if the requested command exists in PATH
if ! command -v "$1" >/dev/null 2>&1; then
    echo "[-] Error: Command '$1' not found in PATH ($PATH)." >&2
    echo "[*] Contents of /usr/local/plan9/bin:" >&2
    ls -la "$PLAN9/bin" || echo "Directory does not exist." >&2
    exit 1
fi

exec "$@"
