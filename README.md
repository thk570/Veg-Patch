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
calendar, harvest and issue logs, compost-day history, notes, and custom
tasks/events added on the Overview page.

Not synced (stays local to each device, or is still static demo content in
this version): the Veg Patch page's bed/pot layout, your chosen visual
theme and light/dark mode, and list sort preferences.
