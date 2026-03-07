#!/usr/bin/env bash
set -euo pipefail

DB_NAME=${DB_NAME:-fitrdb}
DB_USER=${DB_USER:-ambroseblay}
DB_PASSWORD=${DB_PASSWORD:-password}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

export PGPASSWORD="$DB_PASSWORD"

psql -v ON_ERROR_STOP=1 \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USER" \
  -d "$DB_NAME" <<'SQL'
BEGIN;

TRUNCATE TABLE
  public.set_log,
  public.workout_exercise,
  public.workout_session,
  public.plan_exercise,
  public.plan_day,
  public.workout_plan,
  public.body_metric,
  public.location,
  public.user_profile,
  public.exercise,
  public.users
RESTART IDENTITY CASCADE;

-- Keep Flyway metadata, but allow exercise seed migrations to re-run after reset.
DO $$
BEGIN
    IF to_regclass('public.flyway_schema_history') IS NOT NULL THEN
        DELETE FROM public.flyway_schema_history
        WHERE script ILIKE 'V%__seed_system_exercise%';
    END IF;
END $$;

COMMIT;
SQL

psql -v ON_ERROR_STOP=1 \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USER" \
  -d "$DB_NAME" <<'SQL'
SELECT 'users' AS table_name, COUNT(*) AS rows FROM public.users
UNION ALL SELECT 'user_profile', COUNT(*) FROM public.user_profile
UNION ALL SELECT 'location', COUNT(*) FROM public.location
UNION ALL SELECT 'exercise', COUNT(*) FROM public.exercise
UNION ALL SELECT 'workout_plan', COUNT(*) FROM public.workout_plan
UNION ALL SELECT 'plan_day', COUNT(*) FROM public.plan_day
UNION ALL SELECT 'plan_exercise', COUNT(*) FROM public.plan_exercise
UNION ALL SELECT 'workout_session', COUNT(*) FROM public.workout_session
UNION ALL SELECT 'workout_exercise', COUNT(*) FROM public.workout_exercise
UNION ALL SELECT 'set_log', COUNT(*) FROM public.set_log
UNION ALL SELECT 'body_metric', COUNT(*) FROM public.body_metric
ORDER BY table_name;
SQL
