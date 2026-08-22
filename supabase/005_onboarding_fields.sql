-- 005_onboarding_fields.sql
-- Adds patient onboarding fields collected in the post-signup flow:
-- gender, birth_year (with server-side minimum-age enforcement),
-- city, and a completion timestamp used for onboarding routing.

-- 1. Gender — nullable, constrained to exactly two values or null.
--    (Not an enum type: a plain text + CHECK is easier to alter later
--    than a Postgres ENUM, which requires special ALTER TYPE steps.)
ALTER TABLE profiles
  ADD COLUMN gender text;

ALTER TABLE profiles
  ADD CONSTRAINT profiles_gender_check
  CHECK (gender IS NULL OR gender IN ('female', 'male'));

-- 2. Birth year — nullable, but if present must reflect someone at least
--    15 years old as of today. This is evaluated at insert/update time
--    against the CURRENT actual year, not hardcoded to 2026, so the
--    constraint keeps working correctly in future years without another migration.
ALTER TABLE profiles
  ADD COLUMN birth_year integer;

ALTER TABLE profiles
  ADD CONSTRAINT profiles_birth_year_check
  CHECK (
    birth_year IS NULL
    OR (
      birth_year >= 1900
      AND birth_year <= (EXTRACT(YEAR FROM now())::integer - 16)
    )
  );

-- 3. City — nullable at the column level on purpose. It's required by
--    product logic (the onboarding flow won't let you past Step 2 without
--    it), but that's enforced in the app, not the DB — a hard NOT NULL
--    here would break every row that existed before this migration ran.
ALTER TABLE profiles
  ADD COLUMN city text;

-- 4. Onboarding completion marker — lets the app know whether to route
--    a signed-in user into the onboarding flow or straight to Home.
--    Null = not yet completed.
ALTER TABLE profiles
  ADD COLUMN onboarding_completed_at timestamptz;