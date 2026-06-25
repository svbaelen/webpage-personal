# Design: Self-hosted presentation hub on svbaelen.me

**Date:** 2026-06-25
**Status:** Approved, pending implementation

## Goal

Publish self-contained HTML presentations (and similar one-file artifacts)
from any repo or terminal session to a searchable overview page under
`svbaelen.me/talks`. Publishing must be a single command runnable from
anywhere, including other Claude Code sessions working on the presentation.

## Context

The site is a plain static site (`index.html` + `styles.css`, no build step)
served by GitHub Pages in legacy mode from the **root of `main`**. Deploy =
`git push` to `main`. Custom domain `svbaelen.me` via `CNAME`, HTTPS enforced.
The hub fits this model: committed files at `talks/` become live at
`svbaelen.me/talks/`.

## Scope decisions

- **Host files here** (not just link out): presentation HTML is copied into
  this repo so the canonical home is `svbaelen.me/talks/...`.
- **Single self-contained HTML files only** — everything inlined, one file per
  presentation. No asset folders, no build output.
- **Global CLI** for publishing, runnable from any directory.
- **No backend** — overview + search are static, client-side only.

## Architecture

Three pieces.

### 1. Hosting layout

```
talks/
  index.html          # overview + search page
  manifest.json       # array of entries (CLI-maintained)
  slides/
    <slug>.html       # published self-contained files
```

- Hub live at `svbaelen.me/talks/`.
- Each presentation at `svbaelen.me/talks/slides/<slug>.html`.
- No build step; fits the push-to-`main` deploy model.

### 2. The `publish-talk` CLI

- A single bash script, git-tracked at `scripts/publish-talk.sh`.
- Installed once via symlink to `~/.local/bin/publish-talk` (must be on PATH).
- Operates on a cached clone of this repo at `~/.cache/webpage-personal`.

Usage:

```
publish-talk ./my-talk.html \
  --title "Knowledge Maps for Robots" \
  --tags "robotics,kr" \
  --project "Mappalink" \
  --type talk \
  [--slug custom-slug] \
  [--date 2026-06-25] \
  [--desc "one-line description"]
```

Flow:

1. Ensure cache clone exists at `~/.cache/webpage-personal` (clone if absent,
   else `git pull --rebase`).
2. Derive `slug` from `--slug` if given, else slugify `--title`
   (lowercase, spaces/punctuation → hyphens, collapse repeats, trim).
3. Copy the input HTML to `talks/slides/<slug>.html` (overwrite if exists).
4. Update `manifest.json` via `jq`: insert new entry or replace existing one
   matching `slug`.
5. `git add talks/ && git commit -m "Publish talk: <slug>" && git push`.
6. Print the live URL `https://svbaelen.me/talks/slides/<slug>.html`.

Subcommands / flags:

- `--list` — print current manifest entries (slug, title, date) and exit.
- `--remove <slug>` — delete the slide file + manifest entry, commit, push.
- Re-publishing an existing slug overwrites both file and entry (idempotent).

### 3. Overview page (`talks/index.html`)

- Vanilla JS, zero dependencies.
- On load: `fetch('manifest.json')`, render one card per entry showing title,
  date, project, tags, description, and a link to the slide.
- A search box filters client-side, matching across
  title + tags + description + project as the user types.
- Sorted by date descending by default.
- Styled to match the existing site (reuse `styles.css` variables / palette).

## Data model — `manifest.json`

An array of entry objects:

```json
{
  "slug": "knowledge-maps-for-robots",
  "title": "Knowledge Maps for Robots",
  "date": "2026-06-25",
  "tags": ["robotics", "kr"],
  "description": "How dynamic maps carry knowledge for coordination.",
  "project": "Mappalink",
  "type": "talk",
  "file": "slides/knowledge-maps-for-robots.html"
}
```

- `title` (required), `slug` (auto unless `--slug`), `date` (defaults to
  publish date), `tags` (array, optional), `description` (optional),
  `project` (optional), `type` (optional, e.g. `talk`/`demo`/`doc`),
  `file` (relative path, derived).

## Data flow

Other session finishes a `.html` → runs `publish-talk file.html ...` →
cache clone pulled, file copied, manifest updated, committed, pushed →
GitHub Pages rebuilds → live at `svbaelen.me/talks` within ~1 minute.

## Dependencies & error handling

- Requires `git`, `jq`, and SSH push access (already configured).
- Script checks for `git` and `jq` up front; fails with a clear message if
  missing.
- Validates the input file exists and ends in `.html`; refuses an empty
  `--title` (unless `--slug` provided).
- If `git push` is rejected (remote moved), run `git pull --rebase` once and
  retry; if it still fails, abort cleanly leaving the cache clone intact and
  print the error.

## Global memory integration

Append one line to `~/.claude/CLAUDE.md` so every Claude session (in any repo)
knows the command exists:

> Publishing presentations: run `publish-talk <file.html> --title "..."`
> `[--tags --project --type --desc]` from anywhere to publish a self-contained
> HTML presentation to svbaelen.me/talks.

## Out of scope (YAGNI)

- Asset folders / multi-file presentations.
- Server-side search or any backend.
- Authentication / private talks.
- Linking out to externally-hosted presentations (option A from brainstorming).
```