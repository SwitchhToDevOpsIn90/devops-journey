# Session 21 — Docker Introduction

## What was done
- Installed Docker Desktop for Mac (Apple Silicon / arm64 build)
- Pulled and ran hello-world, verified full pull -> create -> run -> exit cycle
- Ran an interactive Ubuntu container (docker run -it ubuntu bash), confirmed real OS isolation by installing tree inside the container and confirming it does NOT exist on the host Mac
- Learned docker ps vs docker ps -a (running only vs all containers including stopped)
- Learned docker start vs docker run - proved a stopped container's filesystem state (installed tree) persists until explicitly removed, not deleted on exit
- Cleaned up test containers with docker rm
- Built a custom image from a Dockerfile (FROM, RUN, CMD), hit a real bug: cowsay installed but not found in $PATH inside the built image
- Diagnosed the bug using find / -name cowsay - same /usr/games PATH gotcha first discovered in Session 20, now recurring in a completely different context (Docker image vs bare EC2 server)
- Fixed by using the full binary path /usr/games/cowsay directly in the Dockerfile CMD instead of relying on PATH
- Made the "layers" concept concrete with docker history - discovered each Dockerfile instruction becomes its own cached layer with its own size (RUN apt install added 100MB, CMD added 0B since it only sets metadata)
- Hit a second real gotcha: docker history my-first-image failed with "No such image" even though docker images clearly showed it existed - worked correctly when referencing the image by ID instead of name
- Checked disk usage (docker system df) and cleaned up unused build cache (docker system prune) - reclaimed 142.1MB without touching the named image

## Why this matters
Docker packages an application with everything it needs into a portable, isolated unit - the shipping-container analogy: a standard box that runs identically on a laptop, a teammate's machine, or production, regardless of what's different underneath. Understanding that stop is not delete, that layers are individually cached, and that image references can be name OR ID are all foundational for every Docker session going forward.

## Verification
- which tree returned nothing on the Mac host, but /usr/bin/tree existed inside the container - proof of isolation
- docker ps -a after docker rm showed a fully empty list - proof of clean removal
- cowsay ran successfully after switching to the full path in CMD
- docker history 72cff09ca26b (by ID) succeeded where docker history my-first-image (by name) failed

## Security note for later sessions
Containers run as root by default unless a Dockerfile explicitly sets a USER instruction. Not a problem for local experiments like today, but worth remembering before anything touches production - a container escape would have root-level access on the host by default.

## Note
This session was local Mac work only (Docker Desktop) - no EC2 server changes, so server-side commit context does not apply this session.
