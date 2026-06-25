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

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
