FROM python:3.11-slim

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ffmpeg curl ca-certificates tini build-essential \
 && rm -rf /var/lib/apt/lists/*

# Persistent dirs
RUN mkdir -p /config /downloads

ARG REPO_URL="https://github.com/coltondick/soulify.git"
ARG REPO_REF="main"

# Clone the repo into /app
RUN git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" /app
WORKDIR /app

# Sanity check
RUN test -f requirements.txt || (echo "requirements.txt not found; ls -la:" && ls -la && exit 1)

# Make helper scripts executable if present
RUN chmod +x sldl 2>/dev/null || true && \
    chmod +x sldlOLD 2>/dev/null || true && \
    chmod +x sldlWB 2>/dev/null || true

# Python deps
RUN pip install --no-cache-dir -r requirements.txt

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD curl -fsS http://localhost:5000/ || exit 1

# Defaults (override in compose)
ENV CONFIG_DIR=/config \
    FLASK_PORT=5000 \
    BASE_URL= \
    SPOTIFY_CLIENT_ID= \
    SPOTIFY_CLIENT_SECRET= \
    SPOTIFY_REDIRECT_URI= \
    SLSK_USERNAME= \
    SLSK_PASSWORD= \
    DOWNLOAD_DIR="/downloads/Music Downloads" \
    PREFERRED_FORMAT="flac" \
    RETAIN_SPECIAL_CHARACTERS="false" \
    DESTINATION_ROOT="/downloads/Music Sorting" \
    SOURCE_ROUTE="/downloads/Music Sorting" \
    NEW_ARTISTS_DIR="/downloads/Music New Artists" \
    UNKNOWN_ALBUMS_DIR="/downloads/Music Unknown Album" \
    UPDATE_METADATA="true" \
    JELLYFIN_REFRESH="true"

# Declare volumes so data isn't baked into the image
VOLUME ["/config", "/downloads"]

EXPOSE 5000

# Run app
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["python", "-u", "SpotWebApp.py"]
