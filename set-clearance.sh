#!/usr/bin/env bash
# Assigns a user's clearance. This is deliberately not an API endpoint: clearance selects the
# Postgres role a user's corpus queries run as, so self-service assignment would be privilege
# escalation. Takes effect on the user's next request — clearance is read per request.
#
#   ./set-clearance.sh                        list users and their clearance
#   ./set-clearance.sh <providerId|email> <PLEBIAN|EQUES|PATRICIAN>
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./env.localdev; set +a

CONTAINER=${PGVECTOR_CONTAINER:-prospero-acl-pgvector-1}

# SQL goes through stdin so psql substitutes :'who' / :'level' as quoted literals.
psql_su() { docker exec -i "$CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 "$@"; }

if [ $# -eq 0 ]; then
  echo "SELECT provider_id, provider, name, email, security_level FROM users ORDER BY created_at;" | psql_su
  exit 0
fi

if [ $# -ne 2 ]; then
  sed -n '6,7p' "$0" | sed 's/^# *//' >&2
  exit 1
fi

case "$2" in
  PLEBIAN|EQUES|PATRICIAN) ;;
  *) echo "Unknown clearance '$2' (expected PLEBIAN, EQUES or PATRICIAN)" >&2; exit 1 ;;
esac

updated=$(echo "UPDATE users SET security_level = :'level', updated_at = now()
               WHERE provider_id = :'who' OR email = :'who'
               RETURNING provider_id, email, security_level;" \
  | psql_su -q -t -A -v who="$1" -v level="$2")

if [ -z "$updated" ]; then
  echo "No user with providerId or email '$1'" >&2
  exit 1
fi
echo "$updated"
