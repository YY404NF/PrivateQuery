#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTPUT_DIR="deploy/release"
SKIP_FRONTEND=0
SKIP_BACKEND=0

usage() {
  cat <<'EOF'
Usage: ./scripts/build-release.sh [--output-dir PATH] [--skip-frontend] [--skip-backend]

Build Ubuntu 24.04 release artifacts into deploy/release by default.
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 20
  fi
}

while (($# > 0)); do
  case "$1" in
    --output-dir)
      if (($# < 2)); then
        echo "--output-dir requires a value" >&2
        exit 1
      fi
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --skip-frontend)
      SKIP_FRONTEND=1
      shift
      ;;
    --skip-backend)
      SKIP_BACKEND=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

OUTPUT_ROOT="$REPO_ROOT/$OUTPUT_DIR"
FRONTEND_OUTPUT="$OUTPUT_ROOT/frontend"
BACKEND_OUTPUT="$OUTPUT_ROOT/backend"

mkdir -p "$OUTPUT_ROOT"

if ((SKIP_FRONTEND == 0)); then
  echo "==> Building frontend"
  require_cmd node
  require_cmd npm

  rm -rf "$FRONTEND_OUTPUT"
  mkdir -p "$FRONTEND_OUTPUT"

  (
    cd "$REPO_ROOT/pq-frontend"
    npm ci
    npm run build
    cp -a dist/. "$FRONTEND_OUTPUT/"
  )
fi

if ((SKIP_BACKEND == 0)); then
  echo "==> Building backend"
  require_cmd go
  require_cmd g++

  rm -rf "$BACKEND_OUTPUT"
  mkdir -p "$BACKEND_OUTPUT"

  (
    cd "$REPO_ROOT/pq-backend"
    export CGO_ENABLED=1
    export GOOS=linux
    export GOARCH=amd64
    go build -trimpath -ldflags="-s -w" -o "$BACKEND_OUTPUT/server-a" ./cmd/server
  )

  cp "$BACKEND_OUTPUT/server-a" "$BACKEND_OUTPUT/server-b"
  cp "$REPO_ROOT/deploy/ubuntu2404/server-a.env" "$BACKEND_OUTPUT/server-a.env"
  cp "$REPO_ROOT/deploy/ubuntu2404/server-b.env" "$BACKEND_OUTPUT/server-b.env"
  cp "$REPO_ROOT/deploy/ubuntu2404/start-server-a.sh" "$BACKEND_OUTPUT/start-server-a.sh"
  cp "$REPO_ROOT/deploy/ubuntu2404/start-server-b.sh" "$BACKEND_OUTPUT/start-server-b.sh"
  chmod +x "$BACKEND_OUTPUT/server-a" "$BACKEND_OUTPUT/server-b" \
    "$BACKEND_OUTPUT/start-server-a.sh" "$BACKEND_OUTPUT/start-server-b.sh"
fi

cp "$REPO_ROOT/deploy/ubuntu2404/README.md" "$OUTPUT_ROOT/README.md"

echo
echo "Release artifacts are ready in: $OUTPUT_ROOT"
