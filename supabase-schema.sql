-- ============================================================
-- study.co — Supabase schema + Row Level Security policies
-- Paste this whole file into Supabase → SQL Editor → Run
-- ============================================================

-- SUBJECTS
create table if not exists subjects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text not null,
  total_time integer not null default 0,
  created_at timestamptz not null default now()
);

-- STUDY SESSIONS (timer history)
create table if not exists sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references subjects(id) on delete set null,
  subject_name text,
  subject_color text,
  start_time timestamptz not null,
  end_time timestamptz not null,
  duration integer not null,
  session_date date not null default current_date
);

-- TASKS
create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  subject_id uuid references subjects(id) on delete set null,
  subject_name text,
  subject_color text,
  due_date date,
  completed boolean not null default false,
  created_at timestamptz not null default now()
);

-- USER SETTINGS (theme, language, pomodoro durations, etc — one row per user)
create table if not exists user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  dark_mode boolean not null default false,
  language text not null default 'en',
  category text not null default 'university',
  theme_style text not null default 'monochrome',
  pomodoro_work integer not null default 25,
  pomodoro_break integer not null default 5
);

-- ============================================================
-- ROW LEVEL SECURITY — every table locked to its owner
-- ============================================================
alter table subjects enable row level security;
alter table sessions enable row level security;
alter table tasks enable row level security;
alter table user_settings enable row level security;

-- SUBJECTS policies
create policy "subjects_select_own" on subjects for select using (auth.uid() = user_id);
create policy "subjects_insert_own" on subjects for insert with check (auth.uid() = user_id);
create policy "subjects_update_own" on subjects for update using (auth.uid() = user_id);
create policy "subjects_delete_own" on subjects for delete using (auth.uid() = user_id);

-- SESSIONS policies
create policy "sessions_select_own" on sessions for select using (auth.uid() = user_id);
create policy "sessions_insert_own" on sessions for insert with check (auth.uid() = user_id);
create policy "sessions_update_own" on sessions for update using (auth.uid() = user_id);
create policy "sessions_delete_own" on sessions for delete using (auth.uid() = user_id);

-- TASKS policies
create policy "tasks_select_own" on tasks for select using (auth.uid() = user_id);
create policy "tasks_insert_own" on tasks for insert with check (auth.uid() = user_id);
create policy "tasks_update_own" on tasks for update using (auth.uid() = user_id);
create policy "tasks_delete_own" on tasks for delete using (auth.uid() = user_id);

-- USER_SETTINGS policies
create policy "settings_select_own" on user_settings for select using (auth.uid() = user_id);
create policy "settings_insert_own" on user_settings for insert with check (auth.uid() = user_id);
create policy "settings_update_own" on user_settings for update using (auth.uid() = user_id);
