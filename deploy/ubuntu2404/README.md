# Ubuntu 24.04 deployment

This directory contains the server-side templates used by the local release build.

## Target ports

- Frontend static site: `15173`
- Server A backend: `18081`
- Server B backend: `18082`

## Release output

Run one of the following commands on the stronger local machine:

```bash
./scripts/build-release.sh
```

or

```powershell
pwsh ./scripts/build-release.ps1
```

Artifacts will be written into `deploy/release/`:

- `frontend/`: static files built from `pq-frontend/dist`
- `backend/server-a`: Linux binary for Server A
- `backend/server-b`: Linux binary for Server B
- `backend/server-a.env`: runtime env for Server A
- `backend/server-b.env`: runtime env for Server B
- `backend/start-server.sh`: startup script for Server A and Server B

If the target server should only `git pull`, commit and push `deploy/release/` after the local build finishes.

## Server deployment

1. `git pull`
2. Copy `deploy/release/frontend/*` into the static-site directory served on port `15173`
3. Place `deploy/release/backend/*` into a backend runtime directory
4. Run:

```bash
chmod +x server-a server-b start-server.sh
./start-server.sh
```

The script uses `nohup` to launch both backends in the background, so they keep running after the terminal is closed. Logs are written to `logs/server-a.log` and `logs/server-b.log`.

The backend binaries create their SQLite sample databases on first startup if the target files do not exist.
