#!/bin/bash
# Proves install.sh on a fresh macOS runner, judged from outside the installer.
#
# Usage: verify-install.sh TOOLS|all [install.sh args...]
#   TOOLS is the space-separated set of tools the args must resolve to.
#   FROM_ZERO=1 runs the first install through the curl bootstrap into $HOME/dotfiles.
#
# Seeds a conflicting file and an unrelated sibling for every second selected package (the
# rest link into an empty home), installs, checks the result, then reruns install.sh with no
# args and checks that nothing changed.
set -euo pipefail

SRC=$(cd "$(dirname "$0")/../.." && pwd -P)
REPO=$SRC
[ "${FROM_ZERO:-0}" = 0 ] || REPO=$HOME/dotfiles
WORK=$(mktemp -d)
EXPECT=$1
shift

PRUNE=(-name .git)
for d in Library work runners hostedtoolcache .Trash .dotfiles-backup; do
  PRUNE+=(-o -path "$HOME/$d")
done

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}
ok() { printf 'ok: %s\n' "$*"; }
has() {
  case " $1 " in *" $2 "*) return 0 ;; esac
  return 1
}

column() { awk -v t="$1" -v c="$2" '!/^[[:space:]]*(#|$)/ && (t == "" || $1 == t) { print $c }' "$SRC/tools.txt"; }
pkg_files() { (cd "$1" && find . -name '.git*' -prune -o -type f -print | sed 's#^\./##'); }
pkg_top_dirs() { (cd "$1" && find . -mindepth 1 -maxdepth 2 -type d ! -name '.git*' | sed 's#^\./##'); }

brew_on() { command -v brew >/dev/null 2>&1; }
on_request() { if brew_on; then brew list --installed-on-request | tr -s ' \t' '\n' | sed '/^$/d' | sort -u; fi; }
casks() { if brew_on; then brew list --cask -1 | sort -u; fi; }
formulae() { if brew_on; then brew list --formula -1 | sort -u; fi; }

ALL=$(column '' 1 | tr '\n' ' ')
[ "$EXPECT" != all ] || EXPECT=$ALL
want_formulae=stow want_casks='' want_stow='' other_stow=''
for t in $EXPECT; do has "$ALL" "$t" || fail "unknown tool $t"; done
for t in $ALL; do
  stow_pkg=$(column "$t" 2)
  if has "$EXPECT" "$t"; then
    for p in $(column "$t" 3 | tr ',' ' '); do
      case $p in
        -) ;;
        cask:*) want_casks="$want_casks ${p##*[:/]}" ;;
        *) want_formulae="$want_formulae ${p##*/}" ;;
      esac
    done
    [ "$stow_pkg" = - ] || want_stow="$want_stow $stow_pkg"
  elif [ "$stow_pkg" != - ]; then
    other_stow="$other_stow $stow_pkg"
  fi
done

SEEDS='' KEEPS=''
seed() {
  local pkg rel keep n=0
  for pkg in $want_stow; do
    n=$((n + 1))
    [ $((n % 2)) = 0 ] || continue
    rel=$(pkg_files "$SRC/$pkg" | awk -F/ '{ print NF "\t" $0 }' | sort -n | sed -n 1p | cut -f2-)
    mkdir -p "$HOME/$(dirname "$rel")" "$WORK/seed/$(dirname "$rel")"
    [ -e "$HOME/$rel" ] || printf 'pre-existing %s\n' "$rel" >"$HOME/$rel"
    cp "$HOME/$rel" "$WORK/seed/$rel"
    keep=$(dirname "$rel")/keep-$pkg.txt
    printf 'keep %s\n' "$pkg" >"$HOME/$keep"
    SEEDS="$SEEDS $rel"
    KEEPS="$KEEPS $keep"
  done
}

check_installed() {
  local have_f have_c f c
  have_f=" $(formulae | tr '\n' ' ') "
  have_c=" $(casks | tr '\n' ' ') "
  for f in $want_formulae; do has "$have_f" "$f" || fail "formula $f is not installed"; done
  for c in $want_casks; do has "$have_c" "$c" || fail "cask $c is not installed"; done
  ok "Homebrew has every selected package:$want_formulae$want_casks"
}

check_linked() {
  local pkg rel d
  for pkg in $want_stow; do
    while IFS= read -r rel; do
      [ "$HOME/$rel" -ef "$REPO/$pkg/$rel" ] || fail "$HOME/$rel is not linked to $pkg/$rel"
    done < <(pkg_files "$REPO/$pkg")
    while IFS= read -r d; do
      if [ -L "$HOME/$d" ] || [ ! -d "$HOME/$d" ]; then fail "$HOME/$d is not a real directory"; fi
    done < <(pkg_top_dirs "$REPO/$pkg")
  done
  ok "every file of$want_stow is linked, and their top two directory levels are real"
}

check_backups() {
  local rel backup k
  for rel in $SEEDS; do
    backup=$(find "$HOME/.dotfiles-backup" -path "*/$rel" -type f 2>/dev/null | sed -n 1p)
    if [ -z "$backup" ] || ! cmp -s "$backup" "$WORK/seed/$rel"; then fail "$HOME/$rel was not backed up intact"; fi
  done
  for k in $KEEPS; do
    if [ -L "$HOME/$k" ] || ! grep -q '^keep ' "$HOME/$k"; then fail "$HOME/$k was disturbed"; fi
  done
  ok "pre-existing files were backed up intact:$SEEDS"
}

check_outside() {
  local f c pkg rel
  while IFS= read -r f; do
    has "$want_formulae" "$f" || fail "formula $f was installed outside the selection"
  done < <(comm -13 "$WORK/on-request.before" <(on_request))
  while IFS= read -r c; do
    has "$want_casks" "$c" || fail "cask $c was installed outside the selection"
  done < <(comm -13 "$WORK/casks.before" <(casks))
  for pkg in $other_stow; do
    while IFS= read -r rel; do
      [ ! "$HOME/$rel" -ef "$REPO/$pkg/$rel" ] || fail "$HOME/$rel is linked, but $pkg is outside the selection"
    done < <(pkg_files "$REPO/$pkg")
  done
  ok "nothing outside the selection is installed or linked (unselected:${other_stow:- none})"
}

snapshot() {
  {
    echo '# brew'
    if brew_on; then
      brew list --versions
      brew list --cask --versions
    fi
    echo '# links'
    find "$HOME" -maxdepth 4 \( "${PRUNE[@]}" \) -prune -o -type l -print | sort | while IFS= read -r l; do
      printf '%s -> %s\n' "$l" "$(readlink "$l")"
    done
    echo '# backups'
    find "$HOME/.dotfiles-backup" 2>/dev/null | sort
    echo '# repo'
    git -C "$REPO" status --porcelain
    cat "$REPO/tools.local"
  } >"$1"
}

check_rerun_is_noop() {
  local newer
  snapshot "$WORK/before-rerun"
  touch "$WORK/marker"
  sleep 1
  "$REPO/install.sh"
  newer=$({
    find "$HOME" -maxdepth 4 \( "${PRUNE[@]}" \) -prune -o -newer "$WORK/marker" -print
    find "$REPO" -name .git -prune -o -newer "$WORK/marker" -print
  } | sort -u)
  [ -z "$newer" ] || fail "the rerun modified: $newer"
  snapshot "$WORK/after-rerun"
  diff -u "$WORK/before-rerun" "$WORK/after-rerun" || fail "the rerun changed Homebrew, links, backups, or the repo"
  ok "a bare rerun changed nothing"
}

on_request >"$WORK/on-request.before"
casks >"$WORK/casks.before"
seed
if [ "${FROM_ZERO:-0}" = 1 ]; then
  [ ! -e "$REPO" ] || fail "$REPO already exists"
  ! brew_on || fail "FROM_ZERO needs a machine without Homebrew"
  (cd "$HOME" && DOTFILES_REPO=$SRC DOTFILES_DIR=$REPO /bin/bash -c "$(cat "$SRC/install.sh")" install.sh ${1+"$@"})
else
  "$REPO/install.sh" ${1+"$@"}
fi

check_installed
check_linked
check_backups
check_outside
check_rerun_is_noop
check_outside
echo "PASS: $EXPECT"
