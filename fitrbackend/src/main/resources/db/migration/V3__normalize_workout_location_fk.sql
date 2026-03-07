-- Normalize workout_session.workout_location_id FK to ON DELETE SET NULL.

DO $$
DECLARE
    location_attnum SMALLINT;
    fk_name TEXT;
BEGIN
    SELECT attnum INTO location_attnum
    FROM pg_attribute
    WHERE attrelid = 'public.workout_session'::regclass
      AND attname = 'workout_location_id'
      AND NOT attisdropped;

    IF location_attnum IS NULL THEN
        RETURN;
    END IF;

    FOR fk_name IN
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'public.workout_session'::regclass
          AND contype = 'f'
          AND array_position(conkey, location_attnum) IS NOT NULL
    LOOP
        EXECUTE format('ALTER TABLE public.workout_session DROP CONSTRAINT IF EXISTS %I', fk_name);
    END LOOP;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.workout_session'::regclass
          AND conname = 'fk_workout_session_location'
    ) THEN
        ALTER TABLE public.workout_session
            ADD CONSTRAINT fk_workout_session_location
            FOREIGN KEY (workout_location_id)
            REFERENCES public.location(id)
            ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_workout_session_location_id
    ON public.workout_session(workout_location_id);
