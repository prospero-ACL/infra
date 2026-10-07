#!/usr/bin/env bash
# Proves the ACL is enforced by Postgres, not by application code: seeds one chunk per book,
# then checks what each tier role can actually see and do. Safe to run against a live dev
# database — it only touches rows it created, and removes them on exit.
set -uo pipefail
cd "$(dirname "$0")"
set -a; . ./env.localdev; set +a

CONTAINER=${PGVECTOR_CONTAINER:-prospero-acl-pgvector-1}
MARK='__acl_verify__'
failures=0

su_sql()   { docker exec "$CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -A -c "$1" 2>&1 | tr -d '\r'; }
role_sql() { docker exec -e PGPASSWORD="$2" "$CONTAINER" psql -U "$1" -d "$POSTGRES_DB" -t -A -c "$3" 2>&1 | tr -d '\r'; }

check() { # label expected actual
  if [ "$2" = "$3" ]; then
    printf '  PASS  %-34s %s\n' "$1" "$3"
  else
    printf '  FAIL  %-34s expected=%s actual=%s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

cleanup() { su_sql "DELETE FROM vector_store WHERE metadata->>'trilogy' = '$MARK';" >/dev/null; }
trap cleanup EXIT

cleanup
su_sql "INSERT INTO vector_store (content, metadata) VALUES
  ('book one text',   '{\"trilogy\":\"$MARK\",\"book\":\"1\"}'::jsonb),
  ('book two text',   '{\"trilogy\":\"$MARK\",\"book\":\"2\"}'::jsonb),
  ('book three text', '{\"trilogy\":\"$MARK\",\"book\":\"3\"}'::jsonb),
  ('unlabelled text', '{\"trilogy\":\"$MARK\"}'::jsonb);" >/dev/null

visible() { role_sql "$1" "$2" \
  "SELECT coalesce(string_agg(metadata->>'book', ',' ORDER BY metadata->>'book'), '') FROM vector_store WHERE metadata->>'trilogy' = '$MARK';"; }

denied() { # role pw sql -> prints "denied" or "allowed"
  case "$(role_sql "$1" "$2" "$3")" in
    *"permission denied"*|*"must be owner"*) echo denied ;;
    *) echo allowed ;;
  esac
}

echo "Row visibility by clearance"
check "plebian reads book 1 only"    "1"     "$(visible postgres_plebian   "$POSTGRES_PLEBIAN_PASSWORD")"
check "eques reads books 1-2"        "1,2"   "$(visible postgres_eques     "$POSTGRES_EQUES_PASSWORD")"
check "patrician reads all books"    "1,2,3" "$(visible postgres_patrician "$POSTGRES_PATRICIAN_PASSWORD")"

echo "Unlabelled chunks fail closed"
check "plebian cannot see unlabelled" "0" "$(role_sql postgres_plebian "$POSTGRES_PLEBIAN_PASSWORD" \
  "SELECT count(*) FROM vector_store WHERE metadata->>'trilogy'='$MARK' AND metadata->>'book' IS NULL;")"

echo "Ingestion is patrician-only"
INS="INSERT INTO vector_store (content, metadata) VALUES ('x','{\"trilogy\":\"$MARK\",\"book\":\"1\"}'::jsonb);"
check "plebian cannot insert"   "denied"  "$(denied postgres_plebian   "$POSTGRES_PLEBIAN_PASSWORD"   "$INS")"
check "eques cannot insert"     "denied"  "$(denied postgres_eques     "$POSTGRES_EQUES_PASSWORD"     "$INS")"
check "patrician can insert"    "allowed" "$(denied postgres_patrician "$POSTGRES_PATRICIAN_PASSWORD" "$INS")"

echo "Tier roles are confined to the corpus"
check "plebian cannot read users"     "denied" "$(denied postgres_plebian   "$POSTGRES_PLEBIAN_PASSWORD"   'SELECT count(*) FROM users;')"
check "patrician cannot read users"   "denied" "$(denied postgres_patrician "$POSTGRES_PATRICIAN_PASSWORD" 'SELECT count(*) FROM users;')"
check "plebian cannot relabel chunks" "denied" "$(denied postgres_plebian   "$POSTGRES_PLEBIAN_PASSWORD" \
  "UPDATE vector_store SET metadata=jsonb_set(metadata,'{book}','\"1\"') WHERE metadata->>'book'='2';")"
check "plebian cannot disable RLS"    "denied" "$(denied postgres_plebian   "$POSTGRES_PLEBIAN_PASSWORD" \
  'ALTER TABLE vector_store DISABLE ROW LEVEL SECURITY;')"

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) FAILED."; fi
exit $((failures > 0))
