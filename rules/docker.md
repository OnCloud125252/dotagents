---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/docker-compose*.yml"
  - "**/docker-compose*.yaml"
  - "**/compose.yml"
  - "**/compose.yaml"
---

# Docker Gotchas

## Engine

- Docker engine: **OrbStack** (`/Applications/OrbStack.app`). `orb start` if `dockerd` not reachable; `orb status` to check.

## Named volumes

- **Named-volume perms only seed on creation** — Docker copies the image directory's contents *and* ownership into a named volume on **first creation only**. If the mount path doesn't pre-exist in the image, the volume is created `root:root 0755` and any non-root `USER` hits `EACCES`. Fix in two places: pre-create the dir + `chown` to the runtime UID in the Dockerfile, **and** `docker volume rm <name>` on already-deployed hosts (the Dockerfile fix alone won't repair existing volumes).

## Entrypoint UID drops

- **`--user` vs gosu/su-exec trap** — many images (e.g. seaweedfs 4.x) drop privileges inside the entrypoint **after** docker honors `--user`, so compose-level `user: "0:0"` is silently ineffective. Diagnostic: `docker exec <c> id` returns root (exec defaults), but `docker top <c> -o user,pid,cmd` shows the real PID 1 UID. Fix: `chown` bind mounts to the runtime UID, not the docker `--user`.

## Container registry probes

- **Docker Hub manifest probes flake on bursts.** Parallel or tight-loop `docker manifest inspect` calls return spurious MISS for images that exist. Use sequential probes with `sleep 1` between, or hit the tags API directly: `curl -s "https://hub.docker.com/v2/repositories/<org>/<repo>/tags?page_size=20"`.
