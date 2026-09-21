# Veg Plot Planner

A single-page web app for planning, logging and tracking a home vegetable
plot — seed inventory, a month-by-month planting calendar, a live bed/pot
status board, and per-year harvest stats. Built as one self-contained HTML
file (`docs/index.html`) with no build step, deployed as a static site via
GitHub Pages, and synced across devices with Supabase.

Live app: `https://<your-username>.github.io/<your-repo-name>/`

## Setup

First-time setup (Supabase table + GitHub Pages) is a one-off. See
[`SETUP.md`](./SETUP.md) for the full step-by-step walkthrough.

## How it's built

- `docs/index.html` — the entire app: markup, styles and logic in one file,
  no bundler. This is what GitHub Pages serves.
- `.github/workflows/pages.yml` — deploys `docs/` to GitHub Pages via
  GitHub Actions on every push to `main`.
- Cross-device sync is handled client-side with `@supabase/supabase-js`
  (loaded from a CDN, no npm install) against one Postgres table holding
  each user's data as a single JSON blob. See `SETUP.md` for the table
  definition.

## Making changes

Edit `docs/index.html` directly and push to `main` — the GitHub Actions
workflow redeploys automatically within a minute or two. There's no build
step to run first.

## What syncs, and what doesn't

Synced across devices once signed in: seed inventory, the planting
calendar, harvest and issue logs, compost-day history, notes, custom
tasks/events added on the Overview page, which built-in Upcoming Tasks
you've ticked off, and the Veg Patch page's live status — the bed
sections, pots and greenhouse trays, and whatever's currently growing in
each.

Not synced (stays local to each device): your chosen visual theme and
light/dark mode, list sort preferences, and today's date.

## The Veg Patch page

Each planted bed section, pot and greenhouse tray shows what's growing in
it and a small set of actions:

- **✕ (Discard)** — the only thing that clears a tile for good: the plant
  died, was pulled, or is otherwise done. Kept as its own control, separate
  from the menu below, since it's the one irreversible action here.
- **⋮ (more actions)** — a dropdown with Log harvest (once something's
  ready), Log issue, and Move. Move relocates a crop between the
  greenhouse, a pot and a bed section — for hardening off a greenhouse
  seedling out into a pot or straight into the veg patch, or bringing a
  pot or bed crop into the greenhouse over winter.

Adding another action anywhere on this page (for a bed/pot tile or a
greenhouse tray) just means adding one more entry to that same dropdown.
