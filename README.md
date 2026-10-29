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

1. **EC2**: launch a `t3.medium` with Ubuntu 24.04 and a 30 GB gp3 disk.
   Security group inbound rules: 22 from *your IP* only, 80 and 443 from anywhere.
   Never open 5432 or 8000.
2. **Elastic IP**: allocate one and associate it with the instance.
3. **DNS**: at your domain registrar, add an A record such as `rag.example.com` → Elastic IP.
4. **Budget**: in AWS Budgets, create a monthly cost budget (e.g. $40) with an email alert.
5. **Server**: SSH in (`ssh -i key.pem ubuntu@rag.example.com`), then run:

   ```bash
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker ubuntu && exit   # log back in so the group applies
   # 2 GB swap: the Maven build and the JVM need headroom next to Postgres
   sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile \
     && sudo swapon /swapfile && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   mkdir ~/prospero && cd ~/prospero
   git clone https://github.com/prospero-ACL/infra.git
   git clone https://github.com/prospero-ACL/backend.git
   git clone https://github.com/prospero-ACL/frontend.git
   ```

   (For private repos, add a deploy key or use `rsync` from your machine instead.)
6. **Env file**: fill in `env.prod.example` locally and save it as `env.prod`. Use fresh
   secrets: a new JWT secret and new Postgres passwords. Copy it to the server:
   `scp env.prod ubuntu@rag.example.com:~/prospero/infra/`
7. **OAuth apps**: add these redirect URIs:
   - Google Cloud Console: `https://rag.example.com/login/oauth2/code/google`
   - GitHub (allows only one callback per OAuth app, so create a second app for prod):
     `https://rag.example.com/login/oauth2/code/github`
8. **Start**: `cd ~/prospero/infra && ./startup.sh prod`

### Day to day

```bash
cd ~/prospero && for r in infra backend frontend; do git -C $r pull; done
cd infra && ./startup.sh prod                       # rebuild + restart, data kept
docker compose -f docker-compose-prod.yml -p prospero-acl logs -f backend
ENV_FILE=env.prod ./verify-acl.sh
ENV_FILE=env.prod ./set-clearance.sh <email> PATRICIAN
```

Backup: `docker exec prospero-acl-pgvector-1 pg_dump -U postgres postgres > backup.sql`.
You can also take an EBS snapshot of the disk from the EC2 console.
