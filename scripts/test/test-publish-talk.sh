#!/usr/bin/env bash
# Black-box tests for publish-talk.sh. No network: TALKS_REPO_DIR points at a
# local bare-backed clone so `git push` stays local.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../publish-talk.sh"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf 'ok   - %s\n' "$1"; }
nok()  { FAIL=$((FAIL+1)); printf 'FAIL - %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else nok "$1 :: [$2]"; fi; }

# --- slugify unit checks (source the script's functions only) -------------
# PUBLISH_TALK_LIB=1 makes the script define functions and return early.
PUBLISH_TALK_LIB=1 source "$SCRIPT"
check "slugify lowercases + hyphenates" \
  '[ "$(slugify "Knowledge Maps for Robots")" = "knowledge-maps-for-robots" ]'
check "slugify collapses punctuation/repeats" \
  '[ "$(slugify "A,  B!! -- C")" = "a-b-c" ]'
check "slugify trims leading/trailing hyphens" \
  '[ "$(slugify "  Hello, World.  ")" = "hello-world" ]'

# --- validation checks (invoke the script as a subprocess) ----------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo '<!doctype html><title>x</title>' > "$TMP/talk.html"

check "publish without file fails" \
  '! bash "$SCRIPT" --title "X" 2>/dev/null'
check "publish without title or slug fails" \
  '! bash "$SCRIPT" "$TMP/talk.html" 2>/dev/null'
check "publish with non-html file fails" \
  '! bash "$SCRIPT" --title "X" "$TMP/notes.txt" 2>/dev/null'
check "publish with missing file fails" \
  '! bash "$SCRIPT" --title "X" "$TMP/nope.html" 2>/dev/null'

# --- end-to-end publish against a local bare remote -----------------------
BARE="$TMP/remote.git"
git init -q --bare "$BARE"
# seed the bare repo with talks/manifest.json so clone is non-empty
SEED="$TMP/seed"
git clone -q "$BARE" "$SEED"
mkdir -p "$SEED/talks/slides"
echo '[]' > "$SEED/talks/manifest.json"
git -C "$SEED" add . >/dev/null
git -C "$SEED" -c user.email=t@t -c user.name=t commit -qm init
git -C "$SEED" push -q origin HEAD:master 2>/dev/null \
  || git -C "$SEED" push -q origin HEAD:main

export TALKS_REMOTE="$BARE"
export TALKS_REPO_DIR="$TMP/cache"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
       GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

bash "$SCRIPT" "$TMP/talk.html" --title "Hello World" --tags "a,b" \
  --project "Mappalink" --type talk --date 2026-06-25 --desc "hi" >/dev/null

M="$TALKS_REPO_DIR/talks/manifest.json"
check "slide file copied" '[ -f "$TALKS_REPO_DIR/talks/slides/hello-world.html" ]'
check "manifest has one entry" '[ "$(jq length "$M")" = "1" ]'
check "manifest title correct" \
  '[ "$(jq -r ".[0].title" "$M")" = "Hello World" ]'
check "manifest tags parsed to array" \
  '[ "$(jq -r ".[0].tags|join(\",\")" "$M")" = "a,b" ]'
check "manifest file path correct" \
  '[ "$(jq -r ".[0].file" "$M")" = "slides/hello-world.html" ]'

# re-publish same slug overwrites, not duplicates
bash "$SCRIPT" "$TMP/talk.html" --title "Hello World" --desc "updated" >/dev/null
check "re-publish keeps single entry" '[ "$(jq length "$M")" = "1" ]'
check "re-publish updates description" \
  '[ "$(jq -r ".[0].description" "$M")" = "updated" ]'

# --- list + remove --------------------------------------------------------
check "list shows the slug" \
  'bash "$SCRIPT" --list | grep -q "hello-world"'
bash "$SCRIPT" --remove hello-world >/dev/null
check "remove drops manifest entry" '[ "$(jq length "$M")" = "0" ]'
check "remove deletes slide file" \
  '[ ! -f "$TALKS_REPO_DIR/talks/slides/hello-world.html" ]'

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
