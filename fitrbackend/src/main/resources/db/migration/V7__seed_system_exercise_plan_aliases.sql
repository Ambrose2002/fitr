-- Add exact naming aliases from supplied user workout routines.
-- Idempotent: inserts only if a system-defined exercise with the same
-- case-insensitive name does not already exist.

WITH seed(name, measurement_type) AS (
    VALUES
        ('Air Squats', 0),
        ('Bulgarian Split Squats', 4),
        ('Dumbbell Goblet Squats', 4),
        ('Leg Curls', 4)
)
INSERT INTO public.exercise (name, measurement_type, is_system_defined, user_id, created_at)
SELECT
    s.name,
    s.measurement_type,
    TRUE,
    NULL,
    NOW()
FROM seed s
WHERE NOT EXISTS (
    SELECT 1
    FROM public.exercise e
    WHERE e.is_system_defined = TRUE
      AND lower(e.name) = lower(s.name)
);
