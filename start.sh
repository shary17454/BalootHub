#!/usr/bin/env sh
set -eu

PORT="${PORT:-8080}"

exec python3 -m http.server "$PORT" --directory public

