-- Seed a broad, system-defined exercise catalog for out-of-the-box usage.
-- Idempotent: skips existing system-defined exercises by case-insensitive name.

ALTER TABLE public.exercise
    ADD COLUMN IF NOT EXISTS user_id BIGINT;

DO $$
DECLARE
    user_attnum SMALLINT;
BEGIN
    SELECT attnum INTO user_attnum
    FROM pg_attribute
    WHERE attrelid = 'public.exercise'::regclass
      AND attname = 'user_id'
      AND NOT attisdropped;

    IF user_attnum IS NULL THEN
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.exercise'::regclass
          AND contype = 'f'
          AND array_position(conkey, user_attnum) IS NOT NULL
    ) THEN
        ALTER TABLE public.exercise
            ADD CONSTRAINT fk_exercise_user
            FOREIGN KEY (user_id)
            REFERENCES public.users(id);
    END IF;
END $$;

WITH seed(name, measurement_code) AS (
    VALUES
        -- Lower body (loaded)
        ('Back Squat', 'REPS_AND_WEIGHT'),
        ('Front Squat', 'REPS_AND_WEIGHT'),
        ('High-Bar Back Squat', 'REPS_AND_WEIGHT'),
        ('Low-Bar Back Squat', 'REPS_AND_WEIGHT'),
        ('Pause Squat', 'REPS_AND_WEIGHT'),
        ('Tempo Squat', 'REPS_AND_WEIGHT'),
        ('Box Squat', 'REPS_AND_WEIGHT'),
        ('Safety Bar Squat', 'REPS_AND_WEIGHT'),
        ('Zercher Squat', 'REPS_AND_WEIGHT'),
        ('Smith Machine Squat', 'REPS_AND_WEIGHT'),
        ('Hack Squat', 'REPS_AND_WEIGHT'),
        ('Goblet Squat', 'REPS_AND_WEIGHT'),
        ('Dumbbell Squat', 'REPS_AND_WEIGHT'),
        ('Landmine Squat', 'REPS_AND_WEIGHT'),
        ('Leg Press', 'REPS_AND_WEIGHT'),
        ('Single-Leg Press', 'REPS_AND_WEIGHT'),
        ('Belt Squat', 'REPS_AND_WEIGHT'),
        ('Leg Extension', 'REPS_AND_WEIGHT'),
        ('Leg Curl Machine', 'REPS_AND_WEIGHT'),
        ('Seated Leg Curl', 'REPS_AND_WEIGHT'),
        ('Lying Leg Curl', 'REPS_AND_WEIGHT'),
        ('Glute Kickback Machine', 'REPS_AND_WEIGHT'),
        ('Cable Glute Kickback', 'REPS_AND_WEIGHT'),
        ('Hip Abduction Machine', 'REPS_AND_WEIGHT'),
        ('Hip Adduction Machine', 'REPS_AND_WEIGHT'),
        ('Standing Calf Raise Machine', 'REPS_AND_WEIGHT'),
        ('Seated Calf Raise', 'REPS_AND_WEIGHT'),
        ('Donkey Calf Raise', 'REPS_AND_WEIGHT'),
        ('Barbell Calf Raise', 'REPS_AND_WEIGHT'),
        ('Hip Thrust', 'REPS_AND_WEIGHT'),
        ('Barbell Glute Bridge', 'REPS_AND_WEIGHT'),
        ('Cable Pull-Through', 'REPS_AND_WEIGHT'),
        ('Romanian Deadlift', 'REPS_AND_WEIGHT'),
        ('Dumbbell Romanian Deadlift', 'REPS_AND_WEIGHT'),
        ('Single-Leg Romanian Deadlift', 'REPS_AND_WEIGHT'),
        ('Stiff-Leg Deadlift', 'REPS_AND_WEIGHT'),
        ('Conventional Deadlift', 'REPS_AND_WEIGHT'),
        ('Deadlift', 'REPS_AND_WEIGHT'),
        ('Deadlifts', 'REPS_AND_WEIGHT'),
        ('Sumo Deadlift', 'REPS_AND_WEIGHT'),
        ('Trap Bar Deadlift', 'REPS_AND_WEIGHT'),
        ('Deficit Deadlift', 'REPS_AND_WEIGHT'),
        ('Rack Pull', 'REPS_AND_WEIGHT'),
        ('Snatch-Grip Deadlift', 'REPS_AND_WEIGHT'),
        ('Good Morning', 'REPS_AND_WEIGHT'),

        -- Lower body (bodyweight / unilateral)
        ('Air Squat', 'REPS'),
        ('Bodyweight Squat', 'REPS'),
        ('Jump Squat', 'REPS'),
        ('Split Squat', 'REPS_AND_WEIGHT'),
        ('Bulgarian Split Squat', 'REPS_AND_WEIGHT'),
        ('Walking Lunge', 'REPS_AND_WEIGHT'),
        ('Reverse Lunge', 'REPS_AND_WEIGHT'),
        ('Forward Lunge', 'REPS_AND_WEIGHT'),
        ('Smith Machine Lunge', 'REPS_AND_WEIGHT'),
        ('Barbell Lunge', 'REPS_AND_WEIGHT'),
        ('Dumbbell Lunge', 'REPS_AND_WEIGHT'),
        ('Deficit Lunge', 'REPS_AND_WEIGHT'),
        ('Curtsy Lunge', 'REPS_AND_WEIGHT'),
        ('Step-Up', 'REPS_AND_WEIGHT'),
        ('Weighted Step-Up', 'REPS_AND_WEIGHT'),
        ('Single-Leg Calf Raise', 'REPS'),
        ('Tibialis Raise', 'REPS'),
        ('Nordic Hamstring Curl', 'REPS'),

        -- Chest / pressing
        ('Barbell Bench Press', 'REPS_AND_WEIGHT'),
        ('Bench Press', 'REPS_AND_WEIGHT'),
        ('Flat Dumbbell Press', 'REPS_AND_WEIGHT'),
        ('Incline Barbell Bench Press', 'REPS_AND_WEIGHT'),
        ('Incline Dumbbell Press', 'REPS_AND_WEIGHT'),
        ('Decline Barbell Bench Press', 'REPS_AND_WEIGHT'),
        ('Decline Dumbbell Press', 'REPS_AND_WEIGHT'),
        ('Close-Grip Bench Press', 'REPS_AND_WEIGHT'),
        ('Paused Bench Press', 'REPS_AND_WEIGHT'),
        ('Spoto Press', 'REPS_AND_WEIGHT'),
        ('Smith Machine Bench Press', 'REPS_AND_WEIGHT'),
        ('Machine Chest Press', 'REPS_AND_WEIGHT'),
        ('Hammer Strength Chest Press', 'REPS_AND_WEIGHT'),
        ('Seated Chest Press Machine', 'REPS_AND_WEIGHT'),
        ('Dumbbell Floor Press', 'REPS_AND_WEIGHT'),
        ('Barbell Floor Press', 'REPS_AND_WEIGHT'),
        ('Cable Chest Fly', 'REPS_AND_WEIGHT'),
        ('Cable Chest Fly (High to Low)', 'REPS_AND_WEIGHT'),
        ('Cable Chest Fly (Low to High)', 'REPS_AND_WEIGHT'),
        ('Chest Flyes', 'REPS_AND_WEIGHT'),
        ('Dumbbell Chest Fly', 'REPS_AND_WEIGHT'),
        ('Pec Deck Fly', 'REPS_AND_WEIGHT'),
        ('Machine Fly', 'REPS_AND_WEIGHT'),
        ('Svend Press', 'REPS_AND_WEIGHT'),
        ('Plate Press', 'REPS_AND_WEIGHT'),
        ('Dumbbell Pullover', 'REPS_AND_WEIGHT'),
        ('Barbell Pullover', 'REPS_AND_WEIGHT'),

        -- Push-up / dip variants
        ('Push-Up', 'REPS'),
        ('Push-Ups', 'REPS'),
        ('Weighted Push-Up', 'REPS_AND_WEIGHT'),
        ('Close-Grip Push-Up', 'REPS'),
        ('Pike Push-Up', 'REPS'),
        ('Handstand Push-Up', 'REPS'),
        ('Wall Walk', 'REPS'),
        ('Chest Dip', 'REPS'),
        ('Weighted Chest Dip', 'REPS_AND_WEIGHT'),
        ('Triceps Dip', 'REPS'),
        ('Tricep Dips', 'REPS'),
        ('Weighted Triceps Dip', 'REPS_AND_WEIGHT'),
        ('Bench Dip', 'REPS'),
        ('Machine Dip', 'REPS_AND_WEIGHT'),

        -- Back / pull patterns
        ('Pull-Up', 'REPS'),
        ('Pull-Ups', 'REPS'),
        ('Weighted Pull-Up', 'REPS_AND_WEIGHT'),
        ('Neutral-Grip Pull-Up', 'REPS'),
        ('Weighted Neutral-Grip Pull-Up', 'REPS_AND_WEIGHT'),
        ('Chin-Up', 'REPS'),
        ('Weighted Chin-Up', 'REPS_AND_WEIGHT'),
        ('Lat Pulldown', 'REPS_AND_WEIGHT'),
        ('Cable Lat Pulldown', 'REPS_AND_WEIGHT'),
        ('Wide-Grip Lat Pulldown', 'REPS_AND_WEIGHT'),
        ('Cable Lat Pulldown (Wide Grip)', 'REPS_AND_WEIGHT'),
        ('Close-Grip Lat Pulldown', 'REPS_AND_WEIGHT'),
        ('Neutral-Grip Lat Pulldown', 'REPS_AND_WEIGHT'),
        ('Underhand Lat Pulldown', 'REPS_AND_WEIGHT'),
        ('Straight-Arm Pulldown', 'REPS_AND_WEIGHT'),
        ('Barbell Bent-Over Row', 'REPS_AND_WEIGHT'),
        ('Bar bell Bent-Over Rows', 'REPS_AND_WEIGHT'),
        ('Bent Over Rows', 'REPS_AND_WEIGHT'),
        ('Pendlay Row', 'REPS_AND_WEIGHT'),
        ('Yates Row', 'REPS_AND_WEIGHT'),
        ('T-Bar Row', 'REPS_AND_WEIGHT'),
        ('Seal Row', 'REPS_AND_WEIGHT'),
        ('Chest-Supported Row', 'REPS_AND_WEIGHT'),
        ('Dumbbell Row', 'REPS_AND_WEIGHT'),
        ('Single-Arm Dumbbell Row', 'REPS_AND_WEIGHT'),
        ('Seated Cable Row', 'REPS_AND_WEIGHT'),
        ('Wide-Grip Seated Cable Row', 'REPS_AND_WEIGHT'),
        ('Close-Grip Seated Cable Row', 'REPS_AND_WEIGHT'),
        ('Cable Row (Single Arm)', 'REPS_AND_WEIGHT'),
        ('Machine Row', 'REPS_AND_WEIGHT'),
        ('Hammer Strength Row', 'REPS_AND_WEIGHT'),
        ('Inverted Row', 'REPS'),
        ('Weighted Inverted Row', 'REPS_AND_WEIGHT'),
        ('Renegade Row', 'REPS_AND_WEIGHT'),
        ('Landmine Row', 'REPS_AND_WEIGHT'),

        -- Shoulders / traps
        ('Barbell Overhead Press', 'REPS_AND_WEIGHT'),
        ('Shoulder Press', 'REPS_AND_WEIGHT'),
        ('Seated Barbell Overhead Press', 'REPS_AND_WEIGHT'),
        ('Dumbbell Shoulder Press', 'REPS_AND_WEIGHT'),
        ('Arnold Press', 'REPS_AND_WEIGHT'),
        ('Machine Shoulder Press', 'REPS_AND_WEIGHT'),
        ('Smith Machine Overhead Press', 'REPS_AND_WEIGHT'),
        ('Behind-the-Neck Press', 'REPS_AND_WEIGHT'),
        ('Push Press', 'REPS_AND_WEIGHT'),
        ('Landmine Press', 'REPS_AND_WEIGHT'),
        ('Dumbbell Lateral Raise', 'REPS_AND_WEIGHT'),
        ('Dumbbell Lateral Raises', 'REPS_AND_WEIGHT'),
        ('Lateral Raises', 'REPS_AND_WEIGHT'),
        ('Lateral Raises (Drop Set)', 'REPS_AND_WEIGHT'),
        ('Seated Lateral Raise', 'REPS_AND_WEIGHT'),
        ('Cable Lateral Raise', 'REPS_AND_WEIGHT'),
        ('Leaning Cable Lateral Raise', 'REPS_AND_WEIGHT'),
        ('Machine Lateral Raise', 'REPS_AND_WEIGHT'),
        ('Front Raise', 'REPS_AND_WEIGHT'),
        ('Front Raises', 'REPS_AND_WEIGHT'),
        ('Barbell Front Raise', 'REPS_AND_WEIGHT'),
        ('Cable Front Raise', 'REPS_AND_WEIGHT'),
        ('Rear Delt Fly (Dumbbell)', 'REPS_AND_WEIGHT'),
        ('Rear Delt Fly (Machine)', 'REPS_AND_WEIGHT'),
        ('Reverse Pec Deck', 'REPS_AND_WEIGHT'),
        ('Face Pull', 'REPS_AND_WEIGHT'),
        ('Upright Row (Barbell)', 'REPS_AND_WEIGHT'),
        ('Upright Row (Cable)', 'REPS_AND_WEIGHT'),
        ('Barbell Shrug', 'REPS_AND_WEIGHT'),
        ('Dumbbell Shrug', 'REPS_AND_WEIGHT'),
        ('Smith Machine Shrug', 'REPS_AND_WEIGHT'),

        -- Arms
        ('Barbell Curl', 'REPS_AND_WEIGHT'),
        ('Bicep Curls', 'REPS_AND_WEIGHT'),
        ('EZ-Bar Curl', 'REPS_AND_WEIGHT'),
        ('Dumbbell Curl', 'REPS_AND_WEIGHT'),
        ('Seated Dumbbell Curl', 'REPS_AND_WEIGHT'),
        ('Alternating Dumbbell Curl', 'REPS_AND_WEIGHT'),
        ('Incline Dumbbell Curl', 'REPS_AND_WEIGHT'),
        ('Concentration Curl', 'REPS_AND_WEIGHT'),
        ('Preacher Curl', 'REPS_AND_WEIGHT'),
        ('Machine Preacher Curl', 'REPS_AND_WEIGHT'),
        ('Cable Curl', 'REPS_AND_WEIGHT'),
        ('Bayesian Cable Curl', 'REPS_AND_WEIGHT'),
        ('Spider Curl', 'REPS_AND_WEIGHT'),
        ('Hammer Curl', 'REPS_AND_WEIGHT'),
        ('Hammer Curls', 'REPS_AND_WEIGHT'),
        ('Cross-Body Hammer Curl', 'REPS_AND_WEIGHT'),
        ('Reverse Curl (Barbell)', 'REPS_AND_WEIGHT'),
        ('Reverse Curl (Cable)', 'REPS_AND_WEIGHT'),
        ('Zottman Curl', 'REPS_AND_WEIGHT'),
        ('Wrist Curl', 'REPS_AND_WEIGHT'),
        ('Reverse Wrist Curl', 'REPS_AND_WEIGHT'),
        ('Cable Rope Hammer Curl', 'REPS_AND_WEIGHT'),
        ('Triceps Rope Pushdown', 'REPS_AND_WEIGHT'),
        ('Tricep Rope Pushdowns', 'REPS_AND_WEIGHT'),
        ('Tricep Pushdowns', 'REPS_AND_WEIGHT'),
        ('Straight Bar Pushdown', 'REPS_AND_WEIGHT'),
        ('V-Bar Pushdown', 'REPS_AND_WEIGHT'),
        ('Overhead Cable Triceps Extension', 'REPS_AND_WEIGHT'),
        ('Dumbbell Overhead Triceps Extension', 'REPS_AND_WEIGHT'),
        ('EZ-Bar Skull Crusher', 'REPS_AND_WEIGHT'),
        ('Lying Triceps Extension', 'REPS_AND_WEIGHT'),
        ('Cable Kickback', 'REPS_AND_WEIGHT'),
        ('Dumbbell Triceps Kickback', 'REPS_AND_WEIGHT'),
        ('JM Press', 'REPS_AND_WEIGHT'),
        ('French Press (EZ-Bar)', 'REPS_AND_WEIGHT'),

        -- Core (bodyweight)
        ('Plank', 'TIME'),
        ('Side Plank', 'TIME'),
        ('RKC Plank', 'TIME'),
        ('Hollow Body Hold', 'TIME'),
        ('V-Sit Hold', 'TIME'),
        ('Pallof Hold', 'TIME'),
        ('Dead Hang', 'TIME'),
        ('Flutter Kick', 'TIME'),
        ('Bear Crawl', 'TIME'),
        ('Mountain Climber', 'REPS'),
        ('Sit-Up', 'REPS'),
        ('Crunch', 'REPS'),
        ('Cable Crunch', 'REPS_AND_WEIGHT'),
        ('Hanging Leg Raises', 'REPS'),
        ('Hanging Leg Raise', 'REPS'),
        ('Hanging Knee Raises', 'REPS'),
        ('Hanging Knee Raise', 'REPS'),
        ('Toes-to-Bar', 'REPS'),
        ('Ab Rollout', 'REPS'),
        ('Ab Rollouts', 'REPS'),
        ('Stability Ball Rollout', 'REPS'),
        ('GHD Sit-Up', 'REPS'),
        ('Reverse Crunch', 'REPS'),
        ('Bicycle Crunch', 'REPS'),
        ('Dead Bug', 'REPS'),
        ('Bird Dog', 'REPS'),
        ('Dragon Flag', 'REPS'),
        ('Russian Twists', 'REPS'),
        ('Russian Twist', 'REPS'),
        ('Hip Raise', 'REPS'),
        ('Back Extension', 'REPS'),

        -- Core (weighted variants)
        ('Weighted Plank', 'TIME_AND_WEIGHT'),
        ('Weighted Side Plank', 'TIME_AND_WEIGHT'),
        ('Weighted Dead Hang', 'TIME_AND_WEIGHT'),
        ('Weighted Sit-Up', 'REPS_AND_WEIGHT'),
        ('Weighted Sit-Ups', 'REPS_AND_WEIGHT'),
        ('Weighted Russian Twist', 'REPS_AND_WEIGHT'),
        ('Weighted Back Extension', 'REPS_AND_WEIGHT'),
        ('Medicine Ball Slam', 'REPS_AND_WEIGHT'),
        ('Medicine Ball Slams', 'REPS_AND_WEIGHT'),
        ('Woodchopper (Cable)', 'REPS_AND_WEIGHT'),
        ('Pallof Press', 'REPS_AND_WEIGHT'),

        -- Carries / weighted timed work
        ('Farmer''s Hold', 'TIME_AND_WEIGHT'),
        ('Farmer''s Carry', 'TIME_AND_WEIGHT'),
        ('Suitcase Carry', 'TIME_AND_WEIGHT'),
        ('Overhead Carry', 'TIME_AND_WEIGHT'),
        ('Waiter Carry', 'TIME_AND_WEIGHT'),
        ('Yoke Carry', 'TIME_AND_WEIGHT'),
        ('Sandbag Carry', 'TIME_AND_WEIGHT'),
        ('Zercher Carry', 'TIME_AND_WEIGHT'),
        ('Plate Pinch Hold', 'TIME_AND_WEIGHT'),
        ('Trap Bar Hold', 'TIME_AND_WEIGHT'),
        ('Sled Push (Timed)', 'TIME_AND_WEIGHT'),
        ('Sled Pull (Timed)', 'TIME_AND_WEIGHT'),
        ('Prowler Push', 'TIME_AND_WEIGHT'),

        -- Conditioning / plyometric / calisthenics
        ('Jump Rope', 'TIME'),
        ('Jump Rope (Timed)', 'TIME'),
        ('Jumping Jack', 'TIME'),
        ('High Knees', 'TIME'),
        ('Butt Kicks', 'TIME'),
        ('Burpee', 'REPS'),
        ('Burpee Pull-Up', 'REPS'),
        ('Box Jump', 'REPS'),
        ('Box Jumps', 'REPS'),
        ('Depth Jump', 'REPS'),
        ('Broad Jump', 'REPS'),
        ('Tuck Jump', 'REPS'),
        ('Skater Hop', 'REPS'),
        ('Bounding', 'REPS'),
        ('Kettlebell Swing', 'REPS_AND_WEIGHT'),
        ('Battle Rope', 'TIME'),
        ('Battle Ropes', 'TIME'),
        ('Agility Ladder Drill', 'TIME'),
        ('Shuttle Run', 'DISTANCE_AND_TIME'),

        -- Cardio (distance + time)
        ('Treadmill Run', 'DISTANCE_AND_TIME'),
        ('Outdoor Run', 'DISTANCE_AND_TIME'),
        ('Track Run', 'DISTANCE_AND_TIME'),
        ('Jogging', 'DISTANCE_AND_TIME'),
        ('Walking', 'DISTANCE_AND_TIME'),
        ('Outdoor Walk', 'DISTANCE_AND_TIME'),
        ('Treadmill Walk', 'DISTANCE_AND_TIME'),
        ('Incline Treadmill Walk', 'DISTANCE_AND_TIME'),
        ('Hiking', 'DISTANCE_AND_TIME'),
        ('Trail Run', 'DISTANCE_AND_TIME'),
        ('Sprint Intervals', 'DISTANCE_AND_TIME'),
        ('Cycling', 'DISTANCE_AND_TIME'),
        ('Road Cycling', 'DISTANCE_AND_TIME'),
        ('Mountain Biking', 'DISTANCE_AND_TIME'),
        ('Stationary Bike', 'DISTANCE_AND_TIME'),
        ('Spin Bike', 'DISTANCE_AND_TIME'),
        ('Assault Bike', 'DISTANCE_AND_TIME'),
        ('Elliptical', 'DISTANCE_AND_TIME'),
        ('Stair Climber', 'DISTANCE_AND_TIME'),
        ('StepMill', 'DISTANCE_AND_TIME'),
        ('Arc Trainer', 'DISTANCE_AND_TIME'),
        ('Rowing', 'DISTANCE_AND_TIME'),
        ('Ski Erg', 'DISTANCE_AND_TIME'),
        ('Swimming', 'DISTANCE_AND_TIME'),
        ('Lap Swim', 'DISTANCE_AND_TIME'),
        ('Open Water Swim', 'DISTANCE_AND_TIME'),
        ('Rower 500m', 'DISTANCE_AND_TIME'),
        ('Rower 1000m', 'DISTANCE_AND_TIME'),
        ('Rower 2000m', 'DISTANCE_AND_TIME'),

        -- Cardio (calories + time)
        ('Treadmill (Calories)', 'CALORIES_AND_TIME'),
        ('Elliptical (Calories)', 'CALORIES_AND_TIME'),
        ('Stationary Bike (Calories)', 'CALORIES_AND_TIME'),
        ('Assault Bike (Calories)', 'CALORIES_AND_TIME'),
        ('Rowing (Calories)', 'CALORIES_AND_TIME'),
        ('Stair Climber (Calories)', 'CALORIES_AND_TIME'),
        ('StepMill (Calories)', 'CALORIES_AND_TIME'),
        ('Ski Erg (Calories)', 'CALORIES_AND_TIME'),
        ('Arc Trainer (Calories)', 'CALORIES_AND_TIME'),
        ('VersaClimber (Calories)', 'CALORIES_AND_TIME'),
        ('Circuit Training (Calories)', 'CALORIES_AND_TIME'),
        ('HIIT Session (Calories)', 'CALORIES_AND_TIME'),
        ('Aerobics Class (Calories)', 'CALORIES_AND_TIME'),
        ('Dance Cardio (Calories)', 'CALORIES_AND_TIME'),
        ('Boxing Bag Work (Calories)', 'CALORIES_AND_TIME'),

        -- Mobility / recovery (timed)
        ('Stretching Session', 'TIME'),
        ('Mobility Flow', 'TIME'),
        ('Yoga Flow', 'TIME'),
        ('Pilates Session', 'TIME'),
        ('Foam Rolling', 'TIME'),
        ('Breathwork Session', 'TIME'),
        ('Cooldown Walk', 'DISTANCE_AND_TIME'),

        -- Name variants from common user input
        ('Squats', 'REPS_AND_WEIGHT'),
        ('Calf Raises', 'REPS_AND_WEIGHT'),
        ('Chest Fly', 'REPS_AND_WEIGHT'),
        ('Cable Chest Flys', 'REPS_AND_WEIGHT'),
        ('Lat Pulldowns', 'REPS_AND_WEIGHT'),
        ('Barbell Rows', 'REPS_AND_WEIGHT'),
        ('Seated Rows', 'REPS_AND_WEIGHT'),
        ('Shoulder Press (Machine)', 'REPS_AND_WEIGHT'),
        ('Overhead Press', 'REPS_AND_WEIGHT'),
        ('Ab Wheel Rollout', 'REPS')
), normalized AS (
    SELECT
        btrim(name) AS name,
        CASE measurement_code
            WHEN 'REPS' THEN 0
            WHEN 'TIME' THEN 1
            WHEN 'REPS_AND_TIME' THEN 2
            WHEN 'TIME_AND_WEIGHT' THEN 3
            WHEN 'REPS_AND_WEIGHT' THEN 4
            WHEN 'DISTANCE_AND_TIME' THEN 5
            WHEN 'CALORIES_AND_TIME' THEN 6
        END AS measurement_type
    FROM seed
), deduped AS (
    SELECT DISTINCT ON (lower(name))
        name,
        measurement_type
    FROM normalized
    WHERE name <> ''
      AND measurement_type IS NOT NULL
    ORDER BY lower(name), name
)
INSERT INTO public.exercise (name, measurement_type, is_system_defined, user_id, created_at)
SELECT
    d.name,
    d.measurement_type,
    TRUE,
    NULL,
    NOW()
FROM deduped d
WHERE NOT EXISTS (
    SELECT 1
    FROM public.exercise e
    WHERE e.is_system_defined = TRUE
      AND lower(e.name) = lower(d.name)
);
