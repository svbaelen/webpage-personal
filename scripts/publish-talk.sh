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

echo "cmd=$CMD title=$TITLE slug=$SLUG file=$FILE"  # placeholder; later tasks replace
