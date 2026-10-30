#!/usr/bin/env bash
# ==============================================================================
# Podman Runner for Plan 9 / plan9port Container Environment
# Enhanced with automatic exit cleanup and container health checks
# ==============================================================================

set -euo pipefail

IMAGE_NAME="plan9port-env"
CONTAINER_NAME="plan9-workspace"
WORKSPACE_DIR="${HOME}/dashboard"

# Build from this script's directory, so the Containerfile is found
# no matter where the script is invoked from.
cd "$(dirname "$0")"

# Ensure local workspace directory exists
mkdir -p "$WORKSPACE_DIR"

# 1. Build container image if not already present
if ! podman image exists "$IMAGE_NAME"; then
    echo "[*] Building Plan 9 container image..."
    podman build -t "$IMAGE_NAME" .
fi

# 2. Define robust cleanup routine on exit, interrupt, or termination
cleanup() {
    echo ""
    echo "[*] Tearing down container and cleaning up environment..."

    # Forcefully stop and remove container if still active
    if podman container exists "$CONTAINER_NAME"; then
        podman rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi

    # Revoke local X11 root access permissions
    xhost -local:root 2>/dev/null || true

    echo "[+] Cleanup complete. Host environment restored."
}
trap cleanup EXIT INT TERM

# 3. Configure X11 forwarding for graphical applications (Acme)
xhost +local:root 2>/dev/null || true

echo "[*] Launching containerized Plan 9 environment..."

# 4. Run Podman with volume mounting, health monitoring, and interactive TTY
# NOTE: no exec here on purpose. exec would replace this shell, and the
# cleanup trap above would never run.
status=0
podman run --rm -it \
    --name "$CONTAINER_NAME" \
    --net=host \
    --env DISPLAY="${DISPLAY:-:0}" \
    --volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
    --volume "$WORKSPACE_DIR:/workspace:z" \
    --health-cmd="pgrep -x rc || pgrep -x bash || exit 1" \
    --health-interval=10s \
    --health-retries=3 \
    "$IMAGE_NAME" "$@" || status=$?
exit $status
