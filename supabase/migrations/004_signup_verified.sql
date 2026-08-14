-- App-level proof that an account finished the *real* signup OTP flow.
--
-- Supabase marks auth.users.email_confirmed_at as a side effect of ANY
-- token flow tied to the address — signup confirmation OR password
-- recovery — so its own confirmation state cannot distinguish "verified by
-- completing signup" from "verified by resetting a password". Someone who
-- abandons the signup OTP screen and goes through forgot-password instead
-- ends up looking confirmed to Supabase while never having completed
-- signup. This column is the app's own answer, set only by the signup OTP
-- flow (and by providers that prove ownership themselves).
alter table public.profiles
  add column signup_verified boolean not null default false;

-- Accounts created through an OAuth provider proved ownership of the
-- address via that provider, so they are signup-verified from birth.
-- Backfills the ones that already exist.
update public.profiles p
set signup_verified = true
from auth.users u
where u.id = p.id
  and coalesce(u.raw_app_meta_data->>'provider', 'email') <> 'email';

-- Same rule, applied at creation time from now on. `provider` is written
-- into raw_app_meta_data by GoTrue as part of the same insert, so it is
-- readable here.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, signup_verified)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_app_meta_data->>'provider', 'email') <> 'email'
  );
  return new;
end;
$$;

-- The flag is a gate, so a client holding a session must not be able to
-- flip it directly — otherwise the exact bypass this migration exists to
-- close (get a session via password recovery, then walk in) is still open,
-- just one REST call further away. UPDATE is re-granted column by column,
-- deliberately omitting signup_verified and role.
revoke update on public.profiles from authenticated;
grant update (full_name, phone) on public.profiles to authenticated;

-- The only sanctioned way to set it, and only ever for the caller's own
-- row. Called by the signup OTP screen once verifyOTP has succeeded.
create or replace function public.mark_signup_verified()
returns void language plpgsql security definer set search_path = ''
as $$
begin
  update public.profiles
  set signup_verified = true
  where id = auth.uid();
end;
$$;

grant execute on function public.mark_signup_verified() to authenticated;
