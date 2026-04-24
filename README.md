# PrivateQuery

PrivateQuery is a two-server private query demo system based on Distributed Point Functions.

## Workspace

- `pq-dpf-core`: portable shared DPF core
- `pq-backend`: Gin + SQLite backend for Server A / Server B
- `pq-frontend`: Vue 3 frontend for home, process, and scene views

## Quick Start

1. Start Server A in development:

```bash
cd pq-backend
go run ./cmd/server
```

2. Start Server B in development:

```bash
cd pq-backend
HOST=0.0.0.0 PORT=8082 PARTY=1 DB_PATH=data/server_b.db go run ./cmd/server
```

3. Start the frontend:

```bash
cd pq-frontend
npm install
npm run dev
```

The backend now binds to `0.0.0.0` by default, and the Vite dev server also binds to `0.0.0.0`, so devices on the same LAN can open the frontend with your machine IP.

The frontend defaults to same-origin proxy paths:

- Server A: `/server-a`
- Server B: `/server-b`

## Ubuntu 24.04 Release Build

When the Ubuntu server is too weak to compile locally, build release artifacts on the Windows workstation first:

```powershell
pwsh ./scripts/build-release.ps1
```

This command builds:

- `deploy/release/frontend/`: static frontend files for the site served on port `15173`
- `deploy/release/backend/server-a`: Linux binary for backend A on port `18081`
- `deploy/release/backend/server-b`: Linux binary for backend B on port `18082`

The script expects WSL distro `Ubuntu-24.04` with `go` and `g++` available for the backend build.

Server-side deployment templates are stored in `deploy/ubuntu2404/`.

## Verification

- Shared core native test: `cd pq-dpf-core && ./scripts/test_native.sh`
- Backend build: `cd pq-backend && go build ./...`
- Frontend build: `cd pq-frontend && npm run build`
