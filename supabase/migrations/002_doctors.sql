-- Doctors: extra clinic details, only for profiles with role = 'doctor'
create table public.doctors (
  id uuid primary key references public.profiles(id) on delete cascade,
  specialty text not null,
  clinic_name text not null,
  city text not null,
  bio text,
  photo_url text,
  consultation_fee numeric,
  show_fee boolean not null default true,
  is_paused boolean not null default false,
  grace_period_minutes int not null default 2,
  delay_by_turns int not null default 2,
  advance_booking_days int not null default 30,
  created_at timestamptz not null default now()
);

alter table public.doctors enable row level security;

create policy "Signed-in users can browse doctors"
  on public.doctors for select to authenticated using (true);

create policy "Doctors update own row"
  on public.doctors for update using (auth.uid() = id);