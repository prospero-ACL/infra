# Infrastructure repo for Prospero ACL

---

## Summary

This contains the infrastructure code for Prospero ACL. It includes Docker
compose scripts tha build the necessary containers for the application, as well
as configuration files for deployment and management of the services.

Additionally it contains copies of some scientific papaers that relevant to the
development of the ACL systems.

Finally it contains the env file that holds all the environment variables.

---

## Usage

Clone the three repos in the parent directory, example:

prospero/frontend
prospero/backend
prospero/infra

Then place the env file in the root of the infra repo.

> [!WARNING]
> the name of the env file must be exactly `env.localdev` for the startup script
> to work. No dot in the beginning.

Then `cd` into the `infra` and run the following command to start the services
in development mode:

```bash
./startup.sh dev
```

> [!NOTE]
> With `./startup.sh clean` It will remove all the containers and volumes
> created by the `dev` command. The database will be reset to its initial state.

---

## Useful Links

- Frontend application here <http://localhost:5173>
- Backend application here <http://localhost:8000>
- Database connection in port 5432(Credentials in the env file)

---

## Production deployment (AWS, single EC2 instance)

The whole stack runs on one EC2 instance with Docker Compose (`docker-compose-prod.yml`).
**Caddy** is the only container that's published (ports 80/443). It gets the Let's Encrypt
certificate on its own, serves the built frontend, and reverse-proxies `/api/*`, `/oauth2/*`
and `/login/oauth2/*` to the backend. Postgres and the backend have no published ports.

```
Internet ─443/80─► caddy ─┬─ /api/* → backend:8000/api/v1/*
                          ├─ /oauth2/*, /login/oauth2/* → backend:8000
                          └─ everything else → React build (SPA fallback)
                   backend ──► pgvector (internal network only)
```

### One-time setup

1. **EC2**: launch a `t3.small` (2 GB; free tier) with Ubuntu LTS (24.04 or 26.04) and a 30 GB gp3 disk.
   Security group inbound rules: 22 from *your IP* only, 80 and 443 from anywhere.
   Never open 5432 or 8000. Under *Advanced details → User data*, paste `ec2-user-data.sh`
   (swap, Docker with compose and buildx). If the instance already exists, run it once
   over SSH instead: `sudo bash ec2-user-data.sh`.
2. **Elastic IP**: allocate one and associate it with the instance.
3. **DNS** (Cloudflare → stackden.eu → DNS → Records → Add record): type `A`, name `prospero`,
   IPv4 = Elastic IP, proxy status **DNS only (grey cloud)**. The orange cloud would break
   Caddy's certificate issuance, cap uploads at 100 MB and time out requests after 100 s.
4. **Budget**: in AWS Budgets, create a monthly cost budget (e.g. $40) with an email alert.
5. **Server**: SSH in (`ssh -i key.pem ubuntu@prospero.stackden.eu`), then run:

   ```bash
   cloud-init status --wait   # wait for user data to finish; log: /var/log/cloud-init-output.log
   docker compose version && free -h
   mkdir ~/prospero && cd ~/prospero
   git clone https://github.com/prospero-ACL/infra.git
   git clone https://github.com/prospero-ACL/backend.git
   git clone https://github.com/prospero-ACL/frontend.git
   ```

   (For private repos, add a deploy key or use `rsync` from your machine instead.)
6. **Env file**: fill in `env.prod.example` locally and save it as `env.prod`, with
   `DOMAIN=prospero.stackden.eu` and `APP_FRONTEND_URL=https://prospero.stackden.eu`. Use fresh
   secrets: a new JWT secret and new Postgres passwords. Copy it to the server:
   `scp -i key.pem env.prod ubuntu@prospero.stackden.eu:~/prospero/infra/`
7. **OAuth apps**: add these redirect URIs:
   - Google Cloud Console: `https://prospero.stackden.eu/login/oauth2/code/google`
   - GitHub (allows only one callback per OAuth app, so create a second app for prod):
     `https://prospero.stackden.eu/login/oauth2/code/github`
8. **Start**: `cd ~/prospero/infra && ./startup.sh prod`

### Day to day

```bash
cd ~/prospero && for r in infra backend frontend; do git -C $r pull; done
cd infra && ./startup.sh prod                       # rebuild + restart, data kept
./startup.sh prod-clean                             # same, but wipes the database (asks yes/no)
docker compose -f docker-compose-prod.yml -p prospero-acl logs -f backend
ENV_FILE=env.prod ./verify-acl.sh
ENV_FILE=env.prod ./set-clearance.sh <email> PATRICIAN
```

Backup: `docker exec prospero-acl-pgvector-1 pg_dump -U postgres postgres > backup.sql`.
You can also take an EBS snapshot of the disk from the EC2 console.
