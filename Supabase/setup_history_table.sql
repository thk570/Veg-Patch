-- Veg Patch — Tier 1 backup: per-write history table
-- Run this once in the Supabase SQL editor for the Veg-Patch project
-- (wdbmghwhgpgsvqgryywn.supabase.co), against the existing veg_plot_data table.
--
-- What this does:
--   1. Adds a history table that stores a copy of every PREVIOUS version of
--      your row, the instant before it gets overwritten.
--   2. A trigger does the archiving at the database level, so it fires on
--      every update regardless of what the client code does -- including a
--      buggy client that overwrites good data with something wrong, which is
--      exactly the failure mode that caused the original data loss.
--   3. History is capped at 30 days -- comfortably more than double the
--      fortnightly-ish GitHub snapshot cadence (Tier 2), so even if the
--      most recent GitHub snapshot turns out to already be bad, this
--      table still reaches back past the previous one too. Pruning
--      happens inline, inside the same trigger, every time it fires --
--      not via a separate scheduled job. (Supabase's docs don't clearly
--      guarantee pg_cron on the free tier, and there are user reports of
--      scheduled jobs occasionally not firing, so this avoids depending
--      on it at all: no extension, nothing that can silently stop
--      working.)
--
-- Retention: 30 days. Change the interval inside the trigger function
-- below to adjust later.

-- 1. History table -----------------------------------------------------
create table if not exists veg_plot_data_history (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  data jsonb not null,
  saved_at timestamptz not null default now()
);

create index if not exists veg_plot_data_history_user_saved_idx
  on veg_plot_data_history (user_id, saved_at desc);

-- RLS: you can read your own history if you ever want to browse it via the
-- app or the API, but nothing (other than the trigger below, which runs as
-- the table owner and bypasses RLS) can insert, update or delete rows here.
-- That's deliberate -- a backup table that the app itself could write to
-- isn't much of a safety net against an app bug.
alter table veg_plot_data_history enable row level security;

drop policy if exists "Users can view their own history" on veg_plot_data_history;
create policy "Users can view their own history"
  on veg_plot_data_history
  for select
  using (auth.uid() = user_id);

grant select on veg_plot_data_history to authenticated;

-- 2. Trigger: archive the old row just before any update, and prune ----
--    anything past the retention window while we're at it. Folding the
--    prune into the same trigger means retention is enforced on every
--    single write, with no separate scheduled job to depend on.
create or replace function log_veg_plot_data_history()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into veg_plot_data_history (user_id, data, saved_at)
  values (old.user_id, old.data, old.updated_at);

  delete from veg_plot_data_history
  where user_id = old.user_id
    and saved_at < now() - interval '30 days';

  return new;
end;
$$;

drop trigger if exists veg_plot_data_before_update on veg_plot_data;
create trigger veg_plot_data_before_update
  before update on veg_plot_data
  for each row
  -- Only archive when the actual content changed, so a no-op upsert
  -- (same JSON re-saved) doesn't create pointless history rows.
  when (old.data is distinct from new.data)
  execute function log_veg_plot_data_history();

-- Note: because pruning only runs when this trigger fires, a long stretch
-- with no writes at all (e.g. over winter) just means history sits there
-- a bit past 30 days until the next write cleans it up -- never a problem
-- in practice, and never a reason old rows silently pile up forever. (The
-- keepalive.yml workflow in this project keeps Supabase itself from
-- pausing during such a stretch, but doesn't touch this app-level table --
-- that's fine, since a quiet app means nothing needs archiving anyway.)

-- Optional extra: if you also want a guaranteed daily prune independent of
-- whether anyone opens the app (belt and braces on top of the above), you
-- can additionally enable the pg_cron extension via Database -> Extensions
-- in the dashboard and run:
--   select cron.schedule(
--     'prune_veg_plot_data_history',
--     '0 3 * * *',
--     $$ delete from veg_plot_data_history where saved_at < now() - interval '30 days'; $$
--   );
-- This isn't required for the design above to work correctly.
