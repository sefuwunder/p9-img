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
- `acme-container` — desk integration: runs containerized acme
  against host-mounted 9P trees (see below).
- `acme-theme-bigger.patch` — the acme Theme/Bigger/Smaller
  patch, applied during the image build so container acme has
  the same theme and font-step commands as the patched host build.
- `.github/workflows/ci.yml` — CI: builds the image and
  smoke-tests it (see below).
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

## Desk integration (acme-container)

`acme-container` runs containerized acme against 9P trees that are
already mounted on the host (the `desk acme` flow in p9int): it
binds each mounted tree leaf individually (`$MOUNT_ROOT/cadence`,
`$MOUNT_ROOT/comms/relay`, `$MOUNT_ROOT/comms/outpost`), so the
trees are visible inside the container, and passes its arguments
through to acme.

```sh
chmod +x acme-container
ACME_BIN=/path/to/acme-container desk acme
```

The desk script still starts the services and mounts the trees on
the host; only acme runs in the container. Closing acme ends the
container run and the desk trap unmounts as usual. `MOUNT_ROOT`
(default `/n`) is respected for the bind paths. The container
build applies the acme Theme/Bigger/Smaller patch, so container
acme has the same `Theme`/`Bigger`/`Smaller` commands as the
patched host build; run podman rootless so the container
can read the user-owned FUSE mounts.

## CI

`.github/workflows/ci.yml` builds the image and smoke-tests it on
every push to `main` and every pull request, plus a weekly run on
Mondays (09:00 UTC) to catch upstream drift even when p9-img
itself has not changed. CI builds with docker (the local flow
uses podman; the Containerfile builds the same under both) and
pushes no image anywhere. If the build fails, the first suspects
are the vendored patch no longer applying to current plan9port
master or a break in `./INSTALL`.

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
