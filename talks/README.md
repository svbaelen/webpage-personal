# Talks hub

Self-hosted, searchable overview of self-contained HTML presentations,
served at https://svbaelen.me/talks.

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

Requires `git` and `jq`.
