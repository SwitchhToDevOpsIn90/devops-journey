# Session 22 - Dockerfile

## What was done
- Built a real Flask app (app.py) and requirements.txt from scratch
- Wrote a Dockerfile with FROM, WORKDIR, COPY, RUN, EXPOSE, CMD
- Confirmed COPY requirements.txt before COPY app.py enables layer caching, proved this concretely by editing app.py and timing the rebuild (2.3 seconds total, pip install layer reused from cache)
- Hit a real Mac-specific gotcha: port 5000 conflicts with macOS AirPlay Receiver, resolved by mapping to host port 5001 instead
- Built a multi-stage version of the Dockerfile, builder stage installs dependencies, final stage copies only the installed packages
- Compared image sizes: single-stage 236MB vs multi-stage 220MB, modest reduction since python slim base is already lean and Flask has few dependencies
- Added dockerignore file to prevent git folder, pycache, env files, and the backup Dockerfile from ever entering the build context, directly ties to Session 19 secrets lesson
- Verified the ignore file works, only app.py exists inside the app folder in the final image

## Why this matters
A Dockerfile is a versioned, readable recipe. Unlike docker commit, anyone can rebuild the exact same image from the same steps. Understanding layer caching turns a slow rebuild into a fixable ordering decision. A dockerignore file is the Docker version of the gitignore lesson from Session 19, it prevents secrets or unwanted files from being baked permanently into an image layer.

## Verification
- curl to the running container returned the real Flask response, confirming build run serve worked end to end
- Rebuild timing of 2.3 seconds proved the pip install layer was cached, not re-run
- docker images showed the real size difference between single-stage and multi-stage builds
- docker run flask-docker-app ls /app confirmed dockerignore correctly excluded the backup Dockerfile from the image

## Note
Real reusable project code is included in this repo under session22-dockerfile, containing app.py, requirements.txt, Dockerfile, and dockerignore as an actual portfolio artifact.
