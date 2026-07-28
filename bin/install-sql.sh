#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DATABASE_URL:-}" ]; then
  echo "DATABASE_URL is required" >&2
  exit 1
fi

case "$DATABASE_URL" in
  *\?*) db_url="${DATABASE_URL}&sslmode=disable" ;;
  *) db_url="${DATABASE_URL}?sslmode=disable" ;;
esac

shopt -s nullglob
sql_files=(/martin/sql/*.sql)

if [ ${#sql_files[@]} -eq 0 ]; then
  echo "No SQL files found in /martin/sql" >&2
  exit 1
fi

psql_args=()
for sql_file in "${sql_files[@]}"; do
  echo "Queuing ${sql_file}"
  psql_args+=("-f" "$sql_file")
done

psql "$db_url" -v ON_ERROR_STOP=1 --single-transaction "${psql_args[@]}"
