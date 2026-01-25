-- Initial schema for Flyway-managed Postgres database

CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  firstname VARCHAR(255),
  lastname VARCHAR(255),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMP,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE user_profile (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  height REAL,
  weight REAL,
  experience_level INTEGER,
  goal INTEGER,
  preferred_weight_unit INTEGER,
  preferred_distance_unit INTEGER,
  created_at TIMESTAMP,
  CONSTRAINT fk_user_profile_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT uq_user_profile_user UNIQUE (user_id)
);

CREATE TABLE location (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  name VARCHAR(255),
  address VARCHAR(255),
  CONSTRAINT fk_location_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE exercise (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255),
  measurement_type INTEGER,
  is_system_defined BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE body_metric (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  metric_type INTEGER,
  value REAL,
  recorded_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP,
  CONSTRAINT fk_body_metric_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE workout_plan (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  name VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_workout_plan_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE plan_day (
  id BIGSERIAL PRIMARY KEY,
  workout_plan_id BIGINT,
  day_number INTEGER,
  name VARCHAR(255),
  CONSTRAINT fk_plan_day_workout_plan FOREIGN KEY (workout_plan_id) REFERENCES workout_plan(id) ON DELETE CASCADE
);

CREATE TABLE plan_exercise (
  id BIGSERIAL PRIMARY KEY,
  plan_day_id BIGINT,
  exercise_id BIGINT,
  target_sets INTEGER,
  target_reps INTEGER,
  target_duration_seconds INTEGER,
  target_distance REAL,
  target_calories REAL,
  CONSTRAINT fk_plan_exercise_plan_day FOREIGN KEY (plan_day_id) REFERENCES plan_day(id) ON DELETE CASCADE,
  CONSTRAINT fk_plan_exercise_exercise FOREIGN KEY (exercise_id) REFERENCES exercise(id) ON DELETE CASCADE
);

CREATE TABLE workout_session (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  workout_location_id BIGINT,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  notes TEXT,
  CONSTRAINT fk_workout_session_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_workout_session_location FOREIGN KEY (workout_location_id) REFERENCES location(id) ON DELETE SET NULL
);

CREATE TABLE workout_exercise (
  id BIGSERIAL PRIMARY KEY,
  workout_session_id BIGINT,
  exercise_id BIGINT,
  measurement_type INTEGER,
  CONSTRAINT fk_workout_exercise_session FOREIGN KEY (workout_session_id) REFERENCES workout_session(id) ON DELETE CASCADE,
  CONSTRAINT fk_workout_exercise_exercise FOREIGN KEY (exercise_id) REFERENCES exercise(id) ON DELETE CASCADE
);

CREATE TABLE set_log (
  id BIGSERIAL PRIMARY KEY,
  workout_session_id BIGINT,
  set_number INTEGER,
  completed_at TIMESTAMP NOT NULL DEFAULT NOW(),
  weight REAL,
  reps INTEGER,
  duration_seconds BIGINT,
  distance REAL,
  calories REAL,
  CONSTRAINT fk_set_log_session FOREIGN KEY (workout_session_id) REFERENCES workout_session(id) ON DELETE CASCADE
);

CREATE INDEX idx_location_user_id ON location(user_id);
CREATE INDEX idx_body_metric_user_id ON body_metric(user_id);
CREATE INDEX idx_workout_plan_user_id ON workout_plan(user_id);
CREATE INDEX idx_plan_day_workout_plan_id ON plan_day(workout_plan_id);
CREATE INDEX idx_plan_exercise_plan_day_id ON plan_exercise(plan_day_id);
CREATE INDEX idx_plan_exercise_exercise_id ON plan_exercise(exercise_id);
CREATE INDEX idx_workout_session_user_id ON workout_session(user_id);
CREATE INDEX idx_workout_session_location_id ON workout_session(workout_location_id);
CREATE INDEX idx_workout_exercise_session_id ON workout_exercise(workout_session_id);
CREATE INDEX idx_workout_exercise_exercise_id ON workout_exercise(exercise_id);
CREATE INDEX idx_set_log_workout_session_id ON set_log(workout_session_id);
