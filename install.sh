#!/bin/bash
# Installs the tools in tools.txt: their Homebrew packages, then their stowed configs.
# Must run on the stock macOS bash 3.2, before Homebrew exists.
set -euo pipefail
set -f

REPO_URL=${DOTFILES_REPO:-https://github.com/drewjs/dotfiles.git}
MANIFEST=tools.txt
STATE=tools.local
HERE=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd -P) || HERE=''
REPO=''

PROFILE='' ONLY='' SKIP='' PICK=0 LIST=0 DRY_RUN=0 SELECTING=0
T_NAME=() T_STOW=() T_BREW=() T_NEEDS=() T_PROFILES=() T_ABOUT=()
SELECTED=''
STOW_PKGS=()
CHANGES=0
BACKUP_DIR=''
MOVED=''

usage() {
  cat <<'EOF'
Usage: ./install.sh [--profile NAME | --only A,B | --pick] [--skip A,B] [--list] [--dry-run]

Selection. Saved in tools.local; a bare run reuses it, a first bare run means --profile full.
  --profile NAME   every tool tagged NAME in tools.txt (full = every tool)
  --only A,B       exactly these tools, plus the tools they need
  --skip A,B       leave these tools out
  --pick           choose tools from a list

  --list           print tools, profiles, and the selection, then exit
  -n, --dry-run    print what would change, change nothing
  -h, --help       print this help

From zero:  bash -c "$(curl -fsSL https://raw.githubusercontent.com/drewjs/dotfiles/main/install.sh)"
EOF
}

say() { printf '==> %s\n' "$*"; }
die() {
  printf 'install.sh: %s\n' "$*" >&2
  exit 1
}
changed() { CHANGES=$((CHANGES + 1)); }

# Announces a change; in a dry run, marks it as such and returns 1 so the caller skips it.
act() {
  if [ "$DRY_RUN" = 1 ]; then
    say "[dry run] $*"
    return 1
  fi
  say "$*"
}
has() {
  case " $1 " in *" $2 "*) return 0 ;; esac
  return 1
}

parse_args() {
  while [ $# -gt 0 ]; do
    case $1 in
      --profile | --only | --skip)
        [ $# -ge 2 ] || die "$1 needs a value"
        [ -n "$2" ] || die "$1 needs a value"
        set_selection "$1" "$2"
        shift
        ;;
      --profile=* | --only=* | --skip=*) set_selection "${1%%=*}" "${1#*=}" ;;
      --pick) PICK=1 ;;
      --list) LIST=1 ;;
      -n | --dry-run) DRY_RUN=1 ;;
      -h | --help)
        usage
        exit 0
        ;;
      *) die "unknown option '$1' (see --help)" ;;
    esac
    shift
  done
}

set_selection() {
  SELECTING=1
  case $1 in
    --profile) PROFILE=$2 ;;
    --only) ONLY=$2 ;;
    --skip) SKIP=$2 ;;
  esac
}

tool_index() {
  local i
  for i in "${!T_NAME[@]}"; do
    [ "${T_NAME[$i]}" != "$1" ] || {
      echo "$i"
      return 0
    }
  done
  return 1
}

load_manifest() {
  local line name stow brew needs profiles about i n
  while IFS= read -r line || [ -n "$line" ]; do
    case $line in '' | '#'*) continue ;; esac
    read -r name stow brew needs profiles about <<<"$line"
    [ -n "$profiles" ] || die "$MANIFEST: '$line' has fewer than 5 columns"
    [ ${#T_NAME[@]} -eq 0 ] || ! tool_index "$name" >/dev/null || die "$MANIFEST: '$name' is listed twice"
    [ "$stow" = - ] || [ -d "$REPO/$stow" ] || die "$MANIFEST: '$name' names a missing stow package '$stow'"
    T_NAME+=("$name")
    T_STOW+=("$stow")
    T_BREW+=("$brew")
    T_NEEDS+=("$needs")
    T_PROFILES+=("$profiles")
    T_ABOUT+=("$about")
  done <"$REPO/$MANIFEST"
  [ ${#T_NAME[@]} -gt 0 ] || die "$MANIFEST lists no tools"
  for i in "${!T_NAME[@]}"; do
    for n in ${T_NEEDS[$i]//,/ }; do
      [ "$n" = - ] || tool_index "$n" >/dev/null || die "$MANIFEST: '${T_NAME[$i]}' needs unknown tool '$n'"
    done
  done
}

load_state() {
  local words=()
  read -r -a words <"$REPO/$STATE" || true
  parse_args ${words[@]+"${words[@]}"}
}

save_state() {
  local want
  want=$(request)
  [ ! -f "$REPO/$STATE" ] || [ "$(cat "$REPO/$STATE")" != "$want" ] || return 0
  printf '%s\n' "$want" >"$REPO/$STATE.tmp"
  mv "$REPO/$STATE.tmp" "$REPO/$STATE"
  say "Saved this machine's selection to $STATE: $want"
  changed
}

request() {
  if [ -n "$ONLY" ]; then printf -- '--only %s' "$ONLY"; else printf -- '--profile %s' "$PROFILE"; fi
  [ -z "$SKIP" ] || printf -- ' --skip %s' "$SKIP"
}

resolve() {
  local base='' want='' skips=${SKIP//,/ } t i n grew=1
  for t in $skips; do tool_index "$t" >/dev/null || die "unknown tool '$t' in --skip (see --list)"; done
  if [ -n "$ONLY" ]; then
    for t in ${ONLY//,/ }; do
      tool_index "$t" >/dev/null || die "unknown tool '$t' (see --list)"
      base="$base $t"
    done
  elif [ "$PROFILE" = full ]; then
    base=${T_NAME[*]}
  else
    for i in "${!T_NAME[@]}"; do
      ! has "${T_PROFILES[$i]//,/ }" "$PROFILE" || base="$base ${T_NAME[$i]}"
    done
    [ -n "$base" ] || die "unknown profile '$PROFILE' (see --list)"
  fi
  for t in $base; do has "$skips" "$t" || want="$want $t"; done

  while [ $grew = 1 ]; do
    grew=0
    for t in $want; do
      i=$(tool_index "$t")
      for n in ${T_NEEDS[$i]//,/ }; do
        if [ "$n" = - ] || has "$want" "$n"; then continue; fi
        ! has "$skips" "$n" || die "$t needs $n, so $n cannot be skipped"
        want="$want $n"
        grew=1
      done
    done
  done

  SELECTED=''
  STOW_PKGS=()
  for i in "${!T_NAME[@]}"; do
    has "$want" "${T_NAME[$i]}" || continue
    SELECTED="$SELECTED ${T_NAME[$i]}"
    [ "${T_STOW[$i]}" = - ] || STOW_PKGS+=("${T_STOW[$i]}")
  done
  SELECTED=${SELECTED# }
  [ -n "$SELECTED" ] || die "the selection is empty"
}

pick() {
  local i mark answer t n picked=''
  { : </dev/tty; } 2>/dev/null || die "--pick needs a terminal"
  {
    echo "Tools ([x] = current selection: $(request)):"
    for i in "${!T_NAME[@]}"; do
      mark=' '
      ! has "$SELECTED" "${T_NAME[$i]}" || mark=x
      printf '  %2d [%s] %-9s %s\n' $((i + 1)) "$mark" "${T_NAME[$i]}" "${T_ABOUT[$i]}"
    done
    printf 'Install which tools? Names or numbers, space-separated. Enter keeps [x]: '
  } >/dev/tty
  read -r answer </dev/tty || answer=''
  [ -n "$answer" ] || return 0
  for t in ${answer//,/ }; do
    case $t in
      *[!0-9]*) ;;
      *)
        n=$((t - 1))
        if [ "$n" -lt 0 ] || [ "$n" -ge ${#T_NAME[@]} ]; then die "there is no tool number $t"; fi
        t=${T_NAME[$n]}
        ;;
    esac
    tool_index "$t" >/dev/null || die "unknown tool '$t'"
    picked="$picked,$t"
  done
  PROFILE='' ONLY=${picked#,} SKIP=''
}

list_tools() {
  local i p mark profiles=''
  echo "Tools in $MANIFEST ([x] = selected by $(request)):"
  for i in "${!T_NAME[@]}"; do
    mark=' '
    ! has "$SELECTED" "${T_NAME[$i]}" || mark=x
    printf '  [%s] %-9s %s\n' "$mark" "${T_NAME[$i]}" "${T_ABOUT[$i]}"
    for p in ${T_PROFILES[$i]//,/ }; do
      [ "$p" = - ] || has "$profiles" "$p" || profiles="$profiles $p"
    done
  done
  echo "Profiles: full$profiles"
}

find_brew() {
  local b
  command -v brew 2>/dev/null && return 0
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ ! -x "$b" ] || {
      echo "$b"
      return 0
    }
  done
  return 1
}

ensure_brew() {
  local brew
  if ! brew=$(find_brew); then
    act "Installing Homebrew (asks for your password once)" || return 0
    sudo -n true 2>/dev/null || sudo -v
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew=$(find_brew) || die "Homebrew installed, but brew is not in /opt/homebrew or /usr/local"
    changed
  fi
  eval "$("$brew" shellenv)"
}

install_packages() {
  local have_f='' have_c='' wanted=stow t i p name formulae='' casks='' list=()
  if command -v brew >/dev/null; then
    have_f=" $(brew list --formula -1 | tr '\n' ' ') "
    have_c=" $(brew list --cask -1 | tr '\n' ' ') "
  fi
  for t in $SELECTED; do
    i=$(tool_index "$t")
    wanted="$wanted ${T_BREW[$i]//,/ }"
  done
  for p in $wanted; do
    case $p in
      -) ;;
      cask:*)
        name=${p#cask:}
        has "$have_c" "${name##*/}" || has "$casks" "$name" || casks="$casks $name"
        ;;
      *) has "$have_f" "${p##*/}" || has "$formulae" "$p" || formulae="$formulae $p" ;;
    esac
  done
  if [ -n "$formulae" ]; then
    read -r -a list <<<"$formulae"
    if act "Installing formulae:$formulae"; then brew install "${list[@]}"; fi
    changed
  fi
  if [ -n "$casks" ]; then
    read -r -a list <<<"$casks"
    if act "Installing casks:$casks"; then brew install --cask "${list[@]}"; fi
    changed
  fi
}

init_submodules() {
  local pending paths=()
  [ ${#STOW_PKGS[@]} -gt 0 ] || return 0
  [ -e "$REPO/.git" ] || return 0
  pending=$(cd "$REPO" && git submodule status -- "${STOW_PKGS[@]}" | sed -n 's/^-[0-9a-f]* \([^ ]*\).*/\1/p')
  [ -n "$pending" ] || return 0
  read -r -a paths <<<"$(printf '%s' "$pending" | tr '\n' ' ')"
  if act "Fetching submodules: ${paths[*]}"; then
    git -C "$REPO" submodule update --init --recursive -- "${paths[@]}"
  fi
  changed
}

points_into_repo() {
  local target dir
  target=$(readlink "$1")
  case $target in /*) ;; *) target=$(dirname "$1")/$target ;; esac
  dir=$(cd -P "$(dirname "$target")" 2>/dev/null && pwd -P) || return 1
  case $dir/ in "$REPO"/*) return 0 ;; esac
  return 1
}

backup() {
  local rel=$1
  ! has "$MOVED" "$rel" || return 0
  MOVED="$MOVED $rel"
  changed
  act "Backing up $HOME/$rel" || return 0
  [ -n "$BACKUP_DIR" ] || BACKUP_DIR=$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)-$$
  mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
  mv "$HOME/$rel" "$BACKUP_DIR/$rel"
}

# Walks each path a package will link and moves aside the first thing in the way: a file,
# or a symlink that does not point into this repo. Links into the repo are stow's own.
claim() {
  local rest=$1 sofar='' path
  while [ -n "$rest" ]; do
    case $rest in
      */*)
        sofar=${sofar:+$sofar/}${rest%%/*}
        rest=${rest#*/}
        ;;
      *)
        sofar=${sofar:+$sofar/}$rest
        rest=
        ;;
    esac
    path=$HOME/$sofar
    if [ -L "$path" ]; then
      points_into_repo "$path" || backup "$sofar"
      return 0
    elif [ -d "$path" ] && [ -n "$rest" ]; then
      continue
    elif [ -e "$path" ]; then
      backup "$sofar"
    fi
    return 0
  done
}

backup_conflicts() {
  local pkg rel
  for pkg in ${STOW_PKGS[@]+"${STOW_PKGS[@]}"}; do
    while IFS= read -r rel; do
      claim "${rel#./}"
    done < <(cd "$REPO/$pkg" && find . -name .git -prune -o ! -type d -print)
  done
}

# Stow folds a missing directory into one symlink into the repo. Keeping the top two
# levels real (~/.config, ~/.local/bin, ~/.claude, ~/.config/nvim) keeps the state apps
# write beside their config out of the git checkout.
make_dirs() {
  local pkg d
  for pkg in ${STOW_PKGS[@]+"${STOW_PKGS[@]}"}; do
    while IFS= read -r d; do
      d=$HOME/${d#./}
      [ ! -d "$d" ] || continue
      changed
      if act "Creating $d"; then mkdir -p "$d"; fi
    done < <(cd "$REPO/$pkg" && find . -mindepth 1 -maxdepth 2 -type d ! -name .git)
  done
}

stow_packages() {
  local out n
  [ ${#STOW_PKGS[@]} -gt 0 ] || return 0
  if [ "$DRY_RUN" = 1 ]; then
    say "[dry run] Stowing ${STOW_PKGS[*]}"
    return 0
  fi
  out=$(stow --dir "$REPO" --target "$HOME" --verbose=1 "${STOW_PKGS[@]}" 2>&1) || {
    printf '%s\n' "$out" >&2
    die "stow failed"
  }
  n=$(printf '%s\n' "$out" | grep -c -E '^(LINK|MKDIR|UNLINK|RMDIR):' || true)
  [ "$n" -gt 0 ] || return 0
  say "Stowed ${STOW_PKGS[*]}"
  changed
}

bootstrap() {
  local dir=${DOTFILES_DIR:-$HOME/dotfiles}
  if [ ! -f "$dir/$MANIFEST" ]; then
    [ "$DRY_RUN" = 0 ] || die "a dry run needs a checkout; clone $REPO_URL first"
    [ ! -e "$dir" ] || die "$dir exists but has no $MANIFEST; set DOTFILES_DIR to another path"
    ensure_brew
    say "Cloning $REPO_URL into $dir"
    git clone "$REPO_URL" "$dir"
  fi
  exec /bin/bash "$dir/install.sh" "$@"
}

main() {
  parse_args "$@"
  [ "$PICK" = 0 ] || [ "$SELECTING" = 0 ] || die "--pick cannot be combined with --profile, --only, or --skip"
  [ -f "$HERE/$MANIFEST" ] || bootstrap "$@"
  REPO=$HERE
  load_manifest
  [ "$SELECTING" = 1 ] || [ ! -f "$REPO/$STATE" ] || load_state
  [ -n "$PROFILE$ONLY" ] || PROFILE=full
  [ -z "$PROFILE" ] || [ -z "$ONLY" ] || die "--profile and --only cannot be combined"
  resolve
  if [ "$PICK" = 1 ]; then
    pick
    resolve
  fi
  if [ "$LIST" = 1 ]; then
    list_tools
    return 0
  fi

  say "Selected: $SELECTED"
  [ "$DRY_RUN" = 1 ] || save_state
  ensure_brew
  install_packages
  init_submodules
  backup_conflicts
  make_dirs
  stow_packages

  if [ "$DRY_RUN" = 1 ]; then
    say "Dry run: nothing changed"
  elif [ "$CHANGES" = 0 ]; then
    say "Nothing to do: everything selected is installed and linked"
  else
    say "Done"
    [ -z "$BACKUP_DIR" ] || say "Replaced files are in $BACKUP_DIR"
  fi
}

main "$@"
