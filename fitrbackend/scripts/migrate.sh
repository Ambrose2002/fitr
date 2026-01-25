#!/usr/bin/env bash
set -euo pipefail

DB_URL=${DB_URL:-jdbc:postgresql://localhost:5432/fitrdb}
DB_USER=${DB_USER:-ambroseblay}
DB_PASSWORD=${DB_PASSWORD:-password}

./mvnw -DskipTests flyway:migrate \
  -Dflyway.url="$DB_URL" \
  -Dflyway.user="$DB_USER" \
  -Dflyway.password="$DB_PASSWORD"
