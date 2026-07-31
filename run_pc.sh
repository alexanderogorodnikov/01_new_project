#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT="${GODOT:-godot}"
exec "$GODOT" --xr-mode off --path "$ROOT"
