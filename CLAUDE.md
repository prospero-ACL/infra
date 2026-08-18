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
./startup.sh dev      # tear down, rebuild, and bring up the full local dev stack
./startup.sh -h        # show usage
```

`startup.sh prod` is not implemented yet.

There is no build/lint/test tooling in this repo — those live in `../backend` and `../frontend`.

What `startup.sh dev` actually does:
1. Sources `env.localdev` into the shell environment.
2. `docker compose -f docker-compose-localdev.yml -p prospero-acl down`
3. Removes the `prospero-acl_node_modules` and `prospero-acl_postgres_data` volumes (i.e. every
   `dev` run starts from a clean database and a clean `node_modules` — expect a full `npm ci` and
   an empty Postgres on every run).
4. `docker compose ... up --build`

If you only need one service restarted/rebuilt without wiping volumes, use `docker compose -f
docker-compose-localdev.yml -p prospero-acl up --build <service>` directly instead of the script.

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

All three services load `env.localdev` via `env_file`; `backend` and `pgvector` also explicitly
re-list `POSTGRES_DB`/`POSTGRES_USER`/`POSTGRES_PASSWORD` (and `backend` additionally
`JWT_SECRET`, `GITHUB_CLIENT_ID/SECRET`, `GOOGLE_CLIENT_ID/SECRET`) under `environment:` — when
adding a new env var that the JVM needs to see, it must be added to `env.localdev` **and** to the
`backend` service's `environment:` list, since Spring only picks up variables actually present in
its process environment.

Inside the Compose network, the backend's Postgres datasource points at host `pgvector` (the
service name), not `localhost` — this only resolves inside the Compose network.

## Env files

- `env.localdev` and `env.prod` are gitignored (see `.gitignore`) and are **not** tracked in this
  repo's history — they exist only on disk locally. `env.localdev` currently holds live secrets
  (OAuth client secrets, JWT secret, OpenAI API key, Postgres password) — treat it as sensitive
  and never add/force it into git.
- `env.prod` is referenced by `.gitignore` but there is no `docker-compose-prod.yml` yet and no
  prod path implemented in `startup.sh`.

## Documents

`documents/` holds the thesis proposal (`proposal.md`) and draw.io diagrams
(`ClassDiagram.drawio`, `UseCasesDiagram.drawio`) — design artifacts for the thesis, not part of
the running system.
