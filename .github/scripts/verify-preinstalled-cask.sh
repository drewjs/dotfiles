#!/bin/bash
# Proves a hand-installed Google Chrome.app is skipped, --audit counts it,
# and the second run prints Nothing to do.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd -P)
cd "$ROOT" || exit 1

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[ -d "/Applications/Google Chrome.app" ] || fail "expected /Applications/Google Chrome.app before install"

rm -rf "$HOME/Library/Application Support/dotfiles"

first=$(mktemp)
./install.sh --only chrome >"$first" 2>&1 || {
  cat "$first" >&2
  fail "install failed"
}
cat "$first"
grep -F "Skipping cask google-chrome" "$first" >/dev/null || fail "did not skip google-chrome"
if brew list --cask -1 2>/dev/null | grep -qx google-chrome; then
  fail "brew installed the google-chrome cask"
fi

second=$(mktemp)
./install.sh >"$second" 2>&1 || {
  cat "$second" >&2
  fail "rerun failed"
}
cat "$second"
grep -F "Nothing to do" "$second" >/dev/null || fail "rerun did not print Nothing to do"

audit=$(mktemp)
./install.sh --audit >"$audit" 2>&1 || {
  cat "$audit" >&2
  fail "--audit reported a miss"
}
cat "$audit"
if grep -F "missing cask google-chrome" "$audit" >/dev/null; then
  fail "--audit treated hand-installed Chrome as missing"
fi
grep -F "Audit clean" "$audit" >/dev/null || fail "--audit did not pass"

printf 'PASS: hand-installed Chrome was skipped and audited as present\n'
