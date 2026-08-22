-- 005_onboarding_fields.sql
-- Adds patient onboarding fields collected in the post-signup flow:
-- gender, birth_year (with server-side minimum-age enforcement),
-- city, and a completion timestamp used for onboarding routing.
--
-- NOTE: this file documents a migration that was already applied directly
-- to the live Supabase project (nfsvvifxkwxpyrtwsxxj) via the dashboard/API.
-- It's added here so the repo's migration history matches what's actually
-- live in the database, per our usual practice of versioning schema in git.

-- 1. Gender — nullable, constrained to exactly two values or null.
--    (Not an enum type: a plain text + CHECK is easier to alter later
--    than a Postgres ENUM, which requires special ALTER TYPE steps.)
ALTER TABLE profiles
  ADD COLUMN gender text;

ALTER TABLE profiles
  ADD CONSTRAINT profiles_gender_check
  CHECK (gender IS NULL OR gender IN ('female', 'male'));

-- 2. Birth year — nullable, but if present must reflect someone at least
--    16 years old as of today. Evaluated live against the CURRENT actual
--    year (not hardcoded to 2026), so this keeps working correctly in
--    future years without another migration.
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

-- 5. Column-level UPDATE grants — RLS alone isn't enough here. Without
--    these, Postgres rejects any write to these columns even though RLS
--    would otherwise allow the row update (same lockdown pattern already
--    used to keep patients from writing their own `role` column).
GRANT UPDATE (gender, birth_year, city, onboarding_completed_at)
  ON profiles TO authenticated;

-- 6. Device tokens — stores FCM tokens per user/device for push
--    notifications. Written to when a patient grants notification
--    permission during onboarding (Step 3).
CREATE TABLE device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, fcm_token)
);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- A user can only see/manage their own device token rows.
CREATE POLICY "Users manage their own device tokens"
  ON device_tokens
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
