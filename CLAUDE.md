# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

This repo is the **infra layer** for "Prospero RAG ACL" (an MSc thesis project — see
`documents/proposal.md`): an ACL-aware Retrieval-Augmented Generation system where document
retrieval is gated by database-level access control, so LLM answers are grounded only in
documents the requesting user is authorized to see.

This repo itself contains no application code — only the Docker Compose stack, env files, and
the startup script that wire the sibling repos together. The actual services live in sibling
directories at the same level as `infra/`:

- `../backend/` — Spring Boot (Java 25) API, port 8000. Has its own `CLAUDE.md`.
- `../frontend/` — Vite + React + TypeScript, Mantine UI, Redux Toolkit, port 5173.

`docker-compose-localdev.yml` builds both from those relative paths (`context: ../backend`,
`context: ../frontend`), so this repo must stay checked out as a sibling of `backend/` and
`frontend/` for local dev to work.

## Commands

```bash
./startup.sh dev      # tear down, rebuild, and bring up the full stack, keeping volumes
./startup.sh clean    # same, but wipe the postgres_data and node_modules volumes first
./startup.sh prod     # production stack from env.prod + docker-compose-prod.yml, detached, volumes kept
./startup.sh -h       # show usage
./verify-acl.sh       # prove the Postgres roles + RLS policies at SQL level (11 checks)
./set-clearance.sh    # list users; `./set-clearance.sh <providerId|email> <LEVEL>` assigns one
```

There is no build/lint/test tooling in this repo — those live in `../backend` and `../frontend`.

What `startup.sh` does:
1. Sources `env.localdev` into the shell environment.
2. `docker compose -f docker-compose-localdev.yml -p prospero-acl down`
3. `clean` only: removes the `prospero-acl_node_modules` and `prospero-acl_postgres_data` volumes
   (a fresh database, rebuilt by the backend's Flyway migrations on boot).
4. `docker compose ... up --build`

To restart/rebuild one service, source `env.localdev` and run `docker compose -f
docker-compose-localdev.yml -p prospero-acl up -d --build <service>`. **Always pass
`-p prospero-acl`**: without it Compose uses the project name `infra`, which attaches a different,
empty `infra_postgres_data` volume.

`verify-acl.sh` and `set-clearance.sh` talk to the running `prospero-acl-pgvector-1` container
(override with `PGVECTOR_CONTAINER`) and source `env.localdev` (override with
`ENV_FILE=env.prod` on the server). Clearance is deliberately not settable through the API —
it selects the Postgres role a user's corpus queries run as — so `set-clearance.sh` is the
assignment path; changes apply on the user's next request.

## Architecture: the local stack

Three services on one Compose network, project name `prospero-acl`:

- **pgvector** (`pgvector/pgvector:pg16`) — Postgres with the pgvector extension, port 5432,
  persisted in the `postgres_data` volume. Has a healthcheck (`pg_isready`); `backend` waits on
  `service_healthy` before starting.
- **backend** — built from `../backend/Dockerfile.localdev`, port 8000. Depends on `pgvector`
  being healthy.
- **frontend** — built from `../frontend/Dockerfile.localdev`, port 5173. Bind-mounts
  `../frontend` into `/app` with a separate `node_modules` named volume (so the container's
  `node_modules` doesn't get shadowed by the host mount). Depends on `backend`.

All three services load `env.localdev` via `env_file`, which is enough to put a variable into the
container's environment — the Postgres tier-role passwords and `OPENAI_API_KEY` reach the backend
this way. `backend` and `pgvector` also re-list some variables under `environment:` using
`${...}` interpolation, which is resolved from the **shell** running `docker compose`; that is why
`startup.sh` sources `env.localdev` first, and why running Compose without sourcing it sets those
entries to blank strings that override the `env_file` values.

Inside the Compose network, the backend's Postgres datasource points at host `pgvector` (the
service name), not `localhost` — this only resolves inside the Compose network.

## Architecture: production (single EC2 host)

`docker-compose-prod.yml` runs the same project name `prospero-acl` on one EC2 instance (runbook in
`README.md`). Differences from localdev:

- **caddy** replaces the Vite dev server: built from `../frontend/Dockerfile.prod` (the `vite
  build` output copied into a `caddy:2-alpine` image), with `./Caddyfile` mounted in. It is the
  only published service (80/443). It terminates TLS for `$DOMAIN` with automatic Let's Encrypt, serves
  the SPA, and proxies `/api/*` → `backend:8000/api/v1/*` (mirroring the Vite proxy rewrite),
  plus `/oauth2/*` and `/login/oauth2/*` to the backend. Frontend and API share one origin.
- **backend** is built from `../backend/Dockerfile.prod` (multi-stage, JRE-only runtime). It reads
  `APP_FRONTEND_URL`, `COOKIE_SECURE` and `SHOW_SQL`, which default to the dev values when unset, and relies on
  `server.forward-headers-strategy=framework` so the OAuth redirect URI comes out as `https://$DOMAIN/...`.
- **pgvector** and **backend** publish no ports. Everything comes from `env.prod` via `env_file`
  with no `${...}` interpolation, so sourcing is not required (startup.sh still does it).
- Template for the env file: `env.prod.example` (tracked). Localhost smoke test:
  `env.prod` with `DOMAIN=localhost`, `-p prospero-acl-prodtest` (Caddy's self-signed cert; OAuth
  itself can't complete at localhost).

## Env files

- `env.localdev` and `env.prod` are gitignored (see `.gitignore`) and are **not** tracked in this
  repo's history — they exist only on disk locally. `env.localdev` currently holds live secrets
  (OAuth client secrets, JWT secret, OpenAI API key, Postgres password) — treat it as sensitive
  and never add/force it into git.
- `env.prod` is gitignored too and lives only on the server; `env.prod.example` lists its keys.
  `POSTGRES_DB` must stay `postgres` because the backend's datasource URL hardcodes that database.

## Documents

`documents/` holds the thesis proposal (`proposal.md`) and draw.io diagrams
(`ClassDiagram.drawio`, `UseCasesDiagram.drawio`) — design artifacts for the thesis, not part of
the running system.
