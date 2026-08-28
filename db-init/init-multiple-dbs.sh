#!/usr/bin/env bash
# Runs automatically on first Postgres container startup (via docker-entrypoint-initdb.d).
# Creates one database per microservice - each service only ever talks to its own DB.
set -e

for db in users_db products_db orders_db; do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE $db;
EOSQL
done
