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
