# Talks hub

Self-hosted, searchable overview of self-contained HTML presentations,
served at https://svbaelen.me/p-b1eb7913 (unlisted: an unguessable public
subpath, `noindex`, not linked from the main site — the repo is public, so
this is obscurity, not privacy).

## Layout

- `index.html` — overview + client-side search.
- `manifest.json` — entries (maintained by the `publish-talk` CLI).
- `slides/<slug>.html` — the published presentations.

## Publishing (from anywhere)

One-time install:

    bash scripts/install-publish-talk.sh   # symlinks to ~/.local/bin

Then, from any directory or session:

    publish-talk ./my-talk.html --title "My Talk" \
      --tags "robotics,kr" --project "Mappalink" --type talk

Other commands:

    publish-talk --list
    publish-talk --remove <slug>

The CLI maintains a cached clone at `~/.cache/webpage-personal`, copies the
file into `slides/`, updates `manifest.json`, commits, and pushes. The site
rebuilds via GitHub Pages within ~1 minute.

Requires `git` and `jq`. Single-user tool: don't run two `publish-talk`
commands against the shared cache clone at the same time (a concurrent run
aborts cleanly rather than corrupting anything, but you'd have to retry).
