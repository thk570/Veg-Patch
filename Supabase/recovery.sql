-- Veg Patch — recovery scripts
-- Not meant to be run as a batch. Read each section, pick the one that
-- matches your situation, fill in your email, and run just that one.
-- Always run the "browse" query first to see what's actually available
-- before overwriting anything.

-- Your user id, if you need it for a query below:
--   select id from auth.users where email = 'your-login-email@example.com';


-- ============================================================
-- 0. BROWSE: see what history snapshots exist and when
-- ============================================================
select id, saved_at, jsonb_pretty(data) as data
from veg_plot_data_history
where user_id = (select id from auth.users where email = 'your-login-email@example.com')
order by saved_at desc;

-- Same, but without the full data blob -- just the timestamps, so you can
-- pick a saved_at to restore to:
select id, saved_at
from veg_plot_data_history
where user_id = (select id from auth.users where email = 'your-login-email@example.com')
order by saved_at desc;


-- ============================================================
-- 1. RESTORE: roll back to the most recent history snapshot
--    (i.e. undo whatever the last write did)
-- ============================================================
update veg_plot_data
set data = (
      select data
      from veg_plot_data_history
      where user_id = (select id from auth.users where email = 'your-login-email@example.com')
      order by saved_at desc
      limit 1
    ),
    updated_at = now()
where user_id = (select id from auth.users where email = 'your-login-email@example.com');


-- ============================================================
-- 2. RESTORE: roll back to the closest snapshot at or before a
--    specific point in time (use this if you know roughly when
--    things were still correct)
-- ============================================================
update veg_plot_data
set data = (
      select data
      from veg_plot_data_history
      where user_id = (select id from auth.users where email = 'your-login-email@example.com')
        and saved_at <= '2026-09-24 18:00:00+00'  -- <-- edit this timestamp (UTC)
      order by saved_at desc
      limit 1
    ),
    updated_at = now()
where user_id = (select id from auth.users where email = 'your-login-email@example.com');
-- If this returns "0 rows updated" or sets data to null, there was no
-- history snapshot that old -- either the 30-day window has already
-- passed it, or the row didn't exist yet at that time. Fall back to
-- option 3 below and pull an older point from the GitHub backups instead.


-- ============================================================
-- 3. RESTORE: from a GitHub snapshot (backups/veg_plot_data-*.json
--    in the thk570/Veg-Patch repo)
-- ============================================================
-- Open the dated file you want in the repo, copy the value of its "data"
-- field (the object, not the outer {"data": ..., "updated_at": ...}
-- wrapper), and paste it in place of the placeholder below.
update veg_plot_data
set data = '{"paste the inner data object from the GitHub JSON file here"}'::jsonb,
    updated_at = now()
where user_id = (select id from auth.users where email = 'your-login-email@example.com');


-- ============================================================
-- Sanity check after any restore above: confirm what the row looks
-- like now.
-- ============================================================
select updated_at, jsonb_pretty(data)
from veg_plot_data
where user_id = (select id from auth.users where email = 'your-login-email@example.com');
