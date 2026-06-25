#!/usr/bin/env bash
set -euo pipefail

REMOTE="${TALKS_REMOTE:-git@github.com:svbaelen/webpage-personal.git}"
REPO_DIR="${TALKS_REPO_DIR:-$HOME/.cache/webpage-personal}"

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/-+/-/g; s/^-//; s/-$//'
}

die() { printf 'publish-talk: %s\n' "$1" >&2; exit 1; }

# When sourced for unit tests, define functions and stop here.
if [ "${PUBLISH_TALK_LIB:-0}" = "1" ]; then
  return 0 2>/dev/null || true
fi

# ---- parse args ----------------------------------------------------------
TITLE="" SLUG="" TAGS="" PROJECT="" TYPE="" DATE="" DESC="" FILE=""
CMD="publish"
while [ $# -gt 0 ]; do
  case "$1" in
    --title)   TITLE="$2"; shift 2;;
    --slug)    SLUG="$2"; shift 2;;
    --tags)    TAGS="$2"; shift 2;;
    --project) PROJECT="$2"; shift 2;;
    --type)    TYPE="$2"; shift 2;;
    --date)    DATE="$2"; shift 2;;
    --desc)    DESC="$2"; shift 2;;
    --list)    CMD="list"; shift;;
    --remove)  CMD="remove"; SLUG="$2"; shift 2;;
    -h|--help) CMD="help"; shift;;
    -*)        die "unknown flag: $1";;
    *)         FILE="$1"; shift;;
  esac
done

require_deps() {
  command -v git >/dev/null 2>&1 || die "git is required"
  command -v jq  >/dev/null 2>&1 || die "jq is required"
}

[ "$CMD" = "help" ] && { cat <<'EOF'
Usage: publish-talk <file.html> --title "..." [--slug s] [--tags a,b]
                     [--project p] [--type talk] [--date YYYY-MM-DD] [--desc "..."]
       publish-talk --list
       publish-talk --remove <slug>
EOF
exit 0; }

require_deps

if [ "$CMD" = "publish" ]; then
  [ -n "$FILE" ] || die "no input HTML file given"
  [ -f "$FILE" ] || die "file not found: $FILE"
  case "$FILE" in *.html) ;; *) die "input must be a .html file";; esac
  [ -n "$TITLE" ] || [ -n "$SLUG" ] || die "--title (or --slug) is required"
fi

ensure_repo() {
  if [ ! -d "$REPO_DIR/.git" ]; then
    git clone -q "$REMOTE" "$REPO_DIR" || die "clone failed: $REMOTE"
  else
    git -C "$REPO_DIR" pull -q --rebase || die "pull failed"
  fi
}

manifest_upsert() {  # args: slug title date tags project type desc file
  local m="$REPO_DIR/talks/manifest.json" tmp
  tmp="$(mktemp)"
  [ -f "$m" ] || echo '[]' > "$m"
  # tags: comma list -> json array (empty string -> [])
  jq \
    --arg slug "$1" --arg title "$2" --arg date "$3" \
    --arg tags "$4" --arg project "$5" --arg type "$6" \
    --arg desc "$7" --arg file "$8" '
    ($tags | if . == "" then [] else split(",") | map(gsub("^ +| +$";"")) end) as $t
    | ([{slug:$slug,title:$title,date:$date,tags:$t,description:$desc,
         project:$project,type:$type,file:$file}]
       + map(select(.slug != $slug)))
    | sort_by(.date) | reverse
  ' "$m" > "$tmp" && mv "$tmp" "$m"
}

if [ "$CMD" = "publish" ]; then
  ensure_repo
  [ -n "$SLUG" ] || SLUG="$(slugify "$TITLE")"
  [ -n "$SLUG" ] || die "could not derive slug from title"
  [ -n "$DATE" ] || DATE="$(date +%F)"
  [ -n "$TITLE" ] || TITLE="$SLUG"
  mkdir -p "$REPO_DIR/talks/slides"
  cp "$FILE" "$REPO_DIR/talks/slides/$SLUG.html"
  manifest_upsert "$SLUG" "$TITLE" "$DATE" "$TAGS" "$PROJECT" "$TYPE" \
    "$DESC" "slides/$SLUG.html"
  git -C "$REPO_DIR" add talks
  git -C "$REPO_DIR" commit -q -m "Publish talk: $SLUG"
  git -C "$REPO_DIR" push -q
  printf 'Published: https://svbaelen.me/talks/slides/%s.html\n' "$SLUG"
fi
