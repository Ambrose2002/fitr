-- Align schema drift from previous Hibernate auto-update usage before enabling validate.

ALTER TABLE public.workout_session
    ADD COLUMN IF NOT EXISTS title VARCHAR(255);

ALTER TABLE public.user_profile
    ADD COLUMN IF NOT EXISTS gender INTEGER;

ALTER TABLE public.set_log
    ADD COLUMN IF NOT EXISTS workout_exercise_id BIGINT;

DO $$
DECLARE
    workout_exercise_attnum SMALLINT;
    fk_name TEXT;
BEGIN
    SELECT attnum INTO workout_exercise_attnum
    FROM pg_attribute
    WHERE attrelid = 'public.set_log'::regclass
      AND attname = 'workout_exercise_id'
      AND NOT attisdropped;

    IF workout_exercise_attnum IS NULL THEN
        RETURN;
    END IF;

    FOR fk_name IN
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'public.set_log'::regclass
          AND contype = 'f'
          AND array_position(conkey, workout_exercise_attnum) IS NOT NULL
    LOOP
        EXECUTE format('ALTER TABLE public.set_log DROP CONSTRAINT IF EXISTS %I', fk_name);
    END LOOP;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.set_log'::regclass
          AND conname = 'fk_set_log_workout_exercise'
    ) THEN
        ALTER TABLE public.set_log
            ADD CONSTRAINT fk_set_log_workout_exercise
            FOREIGN KEY (workout_exercise_id)
            REFERENCES public.workout_exercise(id)
            ON DELETE CASCADE;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_set_log_workout_exercise_id
    ON public.set_log(workout_exercise_id);
