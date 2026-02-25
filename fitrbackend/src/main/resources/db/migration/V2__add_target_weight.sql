-- Add target_weight column to plan_exercise table (nullable for backward compatibility)
ALTER TABLE plan_exercise ADD COLUMN IF NOT EXISTS target_weight FLOAT;
