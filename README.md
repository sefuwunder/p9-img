# p9-img

Containerized plan9port workspace: acme, rc, and the rest of the
plan9port suite in a Debian container, run with podman, displaying
on the host X server.

## Files

- `Containerfile` — two-stage build: compile plan9port on
  debian:bookworm-slim, then copy the built tree to
  `/usr/local/plan9` in a slim runtime image.
- `entrypoint.sh` — sets `PLAN9=/usr/local/plan9`, prepends
  `$PLAN9/bin` to `PATH`, and execs the requested command
  (defaults to `rc`).
- `run-plan9.sh` — builds the image if missing, grants local X11
  access, and runs the container with the workspace mounted.
- `.dockerignore` — keeps `.git` out of the build context.

## Quick start

Prerequisites: podman and a running X server on the host.

```sh
chmod +x run-plan9.sh
./run-plan9.sh        # starts rc in the container
./run-plan9.sh acme   # starts acme instead
```

The host directory `~/dashboard` is mounted at `/workspace`
inside the container (the image's working directory).

## Notes

- The first run builds the image, which compiles plan9port and
  takes a while.
- The container uses `--net=host`, so localhost inside the
  container is the host — handy for reaching host services
  (for example 9P ports) from containerized acme.
- X11 forwarding uses the host's `/tmp/.X11-unix` socket plus
  `xhost +local:root`; the runner revokes that grant on exit.
- To mount 9P trees from *inside* the container with 9pfuse,
  add `--device /dev/fuse --cap-add SYS_ADMIN` to the
  `podman run` invocation (not enabled by default).
