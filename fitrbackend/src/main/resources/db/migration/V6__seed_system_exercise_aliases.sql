-- Add high-frequency naming aliases from common workout templates.
-- Idempotent: inserts only if a system-defined exercise with the same
-- case-insensitive name does not already exist.

WITH seed(name, measurement_type) AS (
    VALUES
        ('Kettlebell Swings', 4),
        ('Lunges', 4),
        ('Seated Dumbbell Curls', 4),
        ('Stretch + Mobility Work', 1),
        ('Light Cardio or Stretching', 1),
        ('Rest or Active Recovery', 1),
        ('Conditioning / Calisthenics', 1),
        ('Full Body Functional Training', 1)
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
