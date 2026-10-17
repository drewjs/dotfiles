#!/usr/bin/env bash
# bash 3.2 is the macOS /bin/bash. Avoid associative arrays and empty "${arr[@]}" under set -u.
set -euo pipefail

unset CDPATH
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

reg_n=0
reg_id=()
reg_stow=()
reg_formulae=()
reg_casks=()
reg_depends=()

registry_load() {
  reg_n=0
  reg_id=()
  reg_stow=()
  reg_formulae=()
  reg_casks=()
  reg_depends=()
  local line id stow formulae casks depends
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      '' | \#*) continue ;;
    esac
    id=""
    stow=""
    formulae=""
    casks=""
    depends=""
    # Pipe, not tab. Bash read treats tab as whitespace and drops empty columns.
    IFS='|' read -r id stow formulae casks depends <<<"$line"
    reg_id[reg_n]=$id
    reg_stow[reg_n]=$stow
    reg_formulae[reg_n]=$formulae
    reg_casks[reg_n]=$casks
    reg_depends[reg_n]=$depends
    reg_n=$((reg_n + 1))
  done <"$ROOT/tools.tsv"
}

registry_index() {
  local want=$1 i=0
  while [[ $i -lt $reg_n ]]; do
    if [[ ${reg_id[$i]} == "$want" ]]; then
      printf '%s\n' "$i"
      return 0
    fi
    i=$((i + 1))
  done
  return 1
}

registry_ids() {
  local i=0
  while [[ $i -lt $reg_n ]]; do
    printf '%s\n' "${reg_id[$i]}"
    i=$((i + 1))
  done
}

registry_check() {
  local i=0 j id dep deps
  if [[ $reg_n -eq 0 ]]; then
    echo "tools.tsv has no tools" >&2
    exit 1
  fi
  while [[ $i -lt $reg_n ]]; do
    id=${reg_id[$i]}
    case "$id" in
      *[!a-z0-9-]*)
        echo "bad tool id: $id" >&2
        exit 1
        ;;
    esac
    if [[ ! -d "$ROOT/${reg_stow[$i]}" ]]; then
      echo "missing Stow package: ${reg_stow[$i]}" >&2
      exit 1
    fi
    j=$((i + 1))
    while [[ $j -lt $reg_n ]]; do
      if [[ $id == "${reg_id[$j]}" ]]; then
        echo "duplicate tool: $id" >&2
        exit 1
      fi
      j=$((j + 1))
    done
    deps=${reg_depends[$i]//,/ }
    for dep in $deps; do
      [[ -z $dep ]] && continue
      if ! registry_index "$dep" >/dev/null; then
        echo "$id depends on unknown tool $dep" >&2
        exit 1
      fi
    done
    i=$((i + 1))
  done
}

resolve_path() {
  python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

mtime_ns() {
  python3 -c 'import os, sys; print(os.lstat(sys.argv[1]).st_mtime_ns)' "$1"
}

same_file() {
  local a b
  a=$(resolve_path "$1") || return 1
  b=$(resolve_path "$2") || return 1
  [[ $a == "$b" ]]
}

selection_file() {
  printf '%s\n' "${DOTFILES_TOOLS_FILE:-$HOME/.config/dotfiles/tools}"
}

package_files() {
  find "$1" \( -name .git -o -name .gitmodules \) -prune -o \( -type f -o -type l \) -print | sort
}

package_linked() {
  local pkg=$1
  local dir="$ROOT/$pkg"
  local src rel dest found=0
  while IFS= read -r src; do
    [[ -z $src ]] && continue
    found=1
    rel=${src#"$dir"/}
    dest="$HOME/$rel"
    if [[ ! -e $dest && ! -L $dest ]]; then
      return 1
    fi
    if ! same_file "$dest" "$src"; then
      return 1
    fi
  done < <(package_files "$dir")
  [[ $found -eq 1 ]]
}

backup_stamp() {
  if [[ -z ${DOTFILES_BACKUP_STAMP:-} ]]; then
    DOTFILES_BACKUP_STAMP=$(date -u +%Y%m%dT%H%M%SZ)
  fi
  printf '%s\n' "$HOME/.local/share/dotfiles/backups/$DOTFILES_BACKUP_STAMP"
}

backup_path() {
  local dest=$1
  local rel=${dest#"$HOME"/}
  local base
  base=$(backup_stamp)
  mkdir -p "$base/$(dirname -- "$rel")"
  mv -- "$dest" "$base/$rel"
}

copy_backup() {
  local dest=$1
  local rel=${dest#"$HOME"/}
  local base
  base=$(backup_stamp)
  mkdir -p "$base/$(dirname -- "$rel")"
  cp -a -- "$dest" "$base/$rel"
}

package_for_target() {
  local target=$1
  local i=0 pkg root
  [[ -z $target ]] && return 0
  while [[ $i -lt $reg_n ]]; do
    pkg=${reg_stow[$i]}
    root=$(resolve_path "$ROOT/$pkg")
    case "$target" in
      "$root" | "$root"/*)
        printf '%s\n' "$pkg"
        return 0
        ;;
    esac
    i=$((i + 1))
  done
}

# Stow folding turns ~/.config into one package symlink. A second package then
# has to move that symlink aside or it would write into the first package.
detach_blocking_symlink() {
  local dest=$1
  local dir target pkg
  dir=$(dirname -- "$dest")
  while [[ $dir != "$HOME" && $dir != "/" && -n $dir ]]; do
    if [[ -L $dir ]]; then
      target=$(resolve_path "$dir" || true)
      pkg=$(package_for_target "$target")
      backup_path "$dir"
      if [[ -n $pkg ]]; then
        case " $PRESERVE " in
          *" $pkg "*) ;;
          *) PRESERVE="$PRESERVE $pkg" ;;
        esac
      fi
      return 0
    fi
    [[ -d $dir ]] || return 0
    dir=$(dirname -- "$dir")
  done
}

backup_conflicts() {
  local pkg=$1
  local dir="$ROOT/$pkg"
  local src rel dest
  while IFS= read -r src; do
    [[ -z $src ]] && continue
    rel=${src#"$dir"/}
    dest="$HOME/$rel"
    detach_blocking_symlink "$dest"
    if [[ -e $dest || -L $dest ]]; then
      if same_file "$dest" "$src"; then
        continue
      fi
      backup_path "$dest"
    fi
  done < <(package_files "$dir")
}

stow_package() {
  stow --no-folding --dir="$ROOT" --target="$HOME" "$1"
}

expand_closure() {
  local pending="" item id dep deps idx seen="" next="" guard=0
  for item in "$@"; do
    pending="$pending $item"
  done
  while [[ -n ${pending// /} ]]; do
    guard=$((guard + 1))
    if [[ $guard -gt 40 ]]; then
      echo "dependency cycle in tools.tsv" >&2
      exit 1
    fi
    next=""
    for id in $pending; do
      case " $seen " in
        *" $id "*) continue ;;
      esac
      if ! idx=$(registry_index "$id"); then
        echo "unknown tool: $id" >&2
        exit 1
      fi
      seen="$seen $id"
      printf '%s\n' "$id"
      deps=${reg_depends[$idx]//,/ }
      for dep in $deps; do
        [[ -z $dep ]] && continue
        case " $seen $next " in
          *" $dep "*) ;;
          *) next="$next $dep" ;;
        esac
      done
    done
    pending=$next
  done
}

load_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    return 1
  fi
}

brew_formula_present() {
  command -v brew >/dev/null 2>&1 || return 1
  brew list --formula "$1" >/dev/null 2>&1
}

brew_cask_present() {
  command -v brew >/dev/null 2>&1 || return 1
  brew list --cask "$1" >/dev/null 2>&1
}

install_brew_for_closure() {
  if [[ ${DOTFILES_SKIP_BREW:-} == 1 ]]; then
    return 0
  fi
  if [[ $(uname -s) != Darwin ]]; then
    echo "Homebrew packages install on macOS" >&2
    exit 1
  fi
  if ! load_brew; then
    echo "Homebrew is not installed" >&2
    exit 1
  fi
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_ENV_HINTS=1
  local id idx spec leaf specs
  local seen_f=" " seen_c=" "
  local -a need_f=()
  local -a need_c=()
  for id in $CLOSURE; do
    idx=$(registry_index "$id")
    specs=${reg_formulae[$idx]//,/ }
    for spec in $specs; do
      [[ -z $spec ]] && continue
      leaf=${spec##*/}
      case "$seen_f" in
        *" $leaf "*) continue ;;
      esac
      seen_f="$seen_f$leaf "
      if ! brew_formula_present "$leaf"; then
        need_f[${#need_f[@]}]=$spec
      fi
    done
    specs=${reg_casks[$idx]//,/ }
    for spec in $specs; do
      [[ -z $spec ]] && continue
      leaf=${spec##*/}
      case "$seen_c" in
        *" $leaf "*) continue ;;
      esac
      seen_c="$seen_c$leaf "
      if ! brew_cask_present "$leaf"; then
        need_c[${#need_c[@]}]=$spec
      fi
    done
  done
  if [[ ${#need_f[@]} -gt 0 ]]; then
    brew install "${need_f[@]}"
  fi
  if [[ ${#need_c[@]} -gt 0 ]]; then
    brew install --cask "${need_c[@]}"
  fi
}

link_closure() {
  local pass=0 acted id idx pkg
  while [[ $pass -lt 6 ]]; do
    pass=$((pass + 1))
    acted=0
    for id in $CLOSURE; do
      idx=$(registry_index "$id")
      pkg=${reg_stow[$idx]}
      if package_linked "$pkg"; then
        continue
      fi
      backup_conflicts "$pkg"
      stow_package "$pkg"
      acted=1
    done
    for pkg in $PRESERVE; do
      if package_linked "$pkg"; then
        continue
      fi
      backup_conflicts "$pkg"
      stow_package "$pkg"
      acted=1
    done
    [[ $acted -eq 0 ]] && return 0
  done
  echo "linking did not converge" >&2
  exit 1
}

dotfiles_apply() {
  registry_load
  registry_check
  if [[ $# -eq 0 ]]; then
    echo "no tools selected" >&2
    exit 1
  fi
  local -a req=()
  local id
  for id in "$@"; do
    id=${id//$'\r'/}
    [[ -z $id ]] && continue
    if ! registry_index "$id" >/dev/null; then
      echo "unknown tool: $id" >&2
      exit 1
    fi
    req[${#req[@]}]=$id
  done
  if [[ ${#req[@]} -eq 0 ]]; then
    echo "no tools selected" >&2
    exit 1
  fi
  CLOSURE=$(expand_closure "${req[@]}")
  CLOSURE=$(printf '%s\n' "$CLOSURE" | tr '\n' ' ')
  PRESERVE=""
  DOTFILES_BACKUP_STAMP=""
  install_brew_for_closure
  link_closure
}

emit_tree() {
  local i=0 pkg dir src rel dest spec leaf specs
  local seen_f=" " seen_c=" "
  while [[ $i -lt $reg_n ]]; do
    pkg=${reg_stow[$i]}
    dir="$ROOT/$pkg"
    while IFS= read -r src; do
      [[ -z $src ]] && continue
      rel=${src#"$dir"/}
      dest="$HOME/$rel"
      if [[ ! -e $dest && ! -L $dest ]]; then
        printf 'path\t%s\tabsent\n' "$rel"
      elif [[ -L $dest ]] && same_file "$dest" "$src"; then
        printf 'path\t%s\tlink\t%s\t%s\n' "$rel" "$(resolve_path "$dest")" "$(mtime_ns "$dest")"
      else
        printf 'path\t%s\tother\t%s\n' "$rel" "$(mtime_ns "$dest")"
      fi
    done < <(package_files "$dir")
    specs=${reg_formulae[$i]//,/ }
    for spec in $specs; do
      [[ -z $spec ]] && continue
      leaf=${spec##*/}
      case "$seen_f" in
        *" $leaf "*) continue ;;
      esac
      seen_f="$seen_f$leaf "
      if brew_formula_present "$leaf"; then
        printf 'formula\t%s\tpresent\n' "$leaf"
      else
        printf 'formula\t%s\tabsent\n' "$leaf"
      fi
    done
    specs=${reg_casks[$i]//,/ }
    for spec in $specs; do
      [[ -z $spec ]] && continue
      leaf=${spec##*/}
      case "$seen_c" in
        *" $leaf "*) continue ;;
      esac
      seen_c="$seen_c$leaf "
      if brew_cask_present "$leaf"; then
        printf 'cask\t%s\tpresent\n' "$leaf"
      else
        printf 'cask\t%s\tabsent\n' "$leaf"
      fi
    done
    i=$((i + 1))
  done
}

emit_selection() {
  local file ids
  file=$(selection_file)
  if [[ -f $file ]]; then
    ids=$(sed '/^$/d' "$file" | sort -u | paste -sd ',' -)
    printf 'selection\t%s\n' "$ids"
  else
    printf 'selection\tabsent\n'
  fi
}

dotfiles_snapshot() {
  registry_load
  {
    emit_tree
    emit_selection
  } | sort
}

tool_in_closure() {
  local id=$1
  local item
  for item in $VERIFY_CLOSURE; do
    [[ $item == "$id" ]] && return 0
  done
  return 1
}

formula_required() {
  local leaf=$1
  local i=0 spec specs item
  for item in $VERIFY_CLOSURE; do
    i=0
    while [[ $i -lt $reg_n ]]; do
      if [[ ${reg_id[$i]} == "$item" ]]; then
        specs=${reg_formulae[$i]//,/ }
        for spec in $specs; do
          [[ ${spec##*/} == "$leaf" ]] && return 0
        done
      fi
      i=$((i + 1))
    done
  done
  return 1
}

cask_required() {
  local leaf=$1
  local i=0 spec specs item
  for item in $VERIFY_CLOSURE; do
    i=0
    while [[ $i -lt $reg_n ]]; do
      if [[ ${reg_id[$i]} == "$item" ]]; then
        specs=${reg_casks[$i]//,/ }
        for spec in $specs; do
          [[ ${spec##*/} == "$leaf" ]] && return 0
        done
      fi
      i=$((i + 1))
    done
  done
  return 1
}

line_with_prefix() {
  local file=$1 prefix=$2
  grep -F -- "$prefix" "$file" | head -n 1 || true
}

dotfiles_verify() {
  local before="" all=0
  local -a req=()
  while [[ $# -gt 0 ]]; do
    case $1 in
      --before)
        before=$2
        shift 2
        ;;
      --all)
        all=1
        shift
        ;;
      *)
        req[${#req[@]}]=$1
        shift
        ;;
    esac
  done
  if [[ -z $before || ! -f $before ]]; then
    echo "verify needs --before snapshot" >&2
    exit 2
  fi
  registry_load
  registry_check
  if [[ $all -eq 1 ]]; then
    req=()
    local id
    while IFS= read -r id; do
      req[${#req[@]}]=$id
    done < <(registry_ids)
  fi
  if [[ ${#req[@]} -eq 0 ]]; then
    echo "verify needs tool ids or --all" >&2
    exit 2
  fi
  VERIFY_CLOSURE=$(expand_closure "${req[@]}")
  VERIFY_CLOSURE=$(printf '%s\n' "$VERIFY_CLOSURE" | tr '\n' ' ')
  local after fail=0
  after=$(mktemp)
  dotfiles_snapshot >"$after"
  local i=0 pkg dir src rel prefix after_line before_line source_real leaf specs spec
  while [[ $i -lt $reg_n ]]; do
    pkg=${reg_stow[$i]}
    dir="$ROOT/$pkg"
    if tool_in_closure "${reg_id[$i]}"; then
      while IFS= read -r src; do
        [[ -z $src ]] && continue
        rel=${src#"$dir"/}
        prefix=$(printf 'path\t%s\t' "$rel")
        after_line=$(line_with_prefix "$after" "$prefix")
        source_real=$(resolve_path "$src")
        case "$after_line" in
          *"	link	$source_real	"*) ;;
          *)
            echo "selected tool ${reg_id[$i]} did not link $rel" >&2
            fail=1
            ;;
        esac
      done < <(package_files "$dir")
    else
      while IFS= read -r src; do
        [[ -z $src ]] && continue
        rel=${src#"$dir"/}
        prefix=$(printf 'path\t%s\t' "$rel")
        after_line=$(line_with_prefix "$after" "$prefix")
        before_line=$(line_with_prefix "$before" "$prefix")
        if [[ $after_line != "$before_line" ]]; then
          echo "unselected tool ${reg_id[$i]} changed $rel" >&2
          fail=1
        fi
      done < <(package_files "$dir")
    fi
    i=$((i + 1))
  done
  local skip_packages=0
  if [[ ${DOTFILES_SKIP_BREW:-} == 1 || $(uname -s) != Darwin ]]; then
    skip_packages=1
  fi
  i=0
  local seen_f=" " seen_c=" "
  while [[ $i -lt $reg_n ]]; do
    specs=${reg_formulae[$i]//,/ }
    for spec in $specs; do
      [[ -z $spec ]] && continue
      leaf=${spec##*/}
      case "$seen_f" in
        *" $leaf "*) continue ;;
      esac
      seen_f="$seen_f$leaf "
      prefix=$(printf 'formula\t%s\t' "$leaf")
      after_line=$(line_with_prefix "$after" "$prefix")
      before_line=$(line_with_prefix "$before" "$prefix")
      if formula_required "$leaf"; then
        if [[ $skip_packages -eq 0 && $after_line != "formula	$leaf	present" ]]; then
          echo "selected formula missing: $leaf" >&2
          fail=1
        fi
      elif [[ $after_line != "$before_line" ]]; then
        echo "unselected formula changed: $leaf" >&2
        fail=1
      fi
    done
    specs=${reg_casks[$i]//,/ }
    for spec in $specs; do
      [[ -z $spec ]] && continue
      leaf=${spec##*/}
      case "$seen_c" in
        *" $leaf "*) continue ;;
      esac
      seen_c="$seen_c$leaf "
      prefix=$(printf 'cask\t%s\t' "$leaf")
      after_line=$(line_with_prefix "$after" "$prefix")
      before_line=$(line_with_prefix "$before" "$prefix")
      if cask_required "$leaf"; then
        if [[ $skip_packages -eq 0 && $after_line != "cask	$leaf	present" ]]; then
          echo "selected cask missing: $leaf" >&2
          fail=1
        fi
      elif [[ $after_line != "$before_line" ]]; then
        echo "unselected cask changed: $leaf" >&2
        fail=1
      fi
    done
    i=$((i + 1))
  done
  rm -f "$after"
  [[ $fail -eq 0 ]]
}

parse_id_list() {
  local raw=$1 norm id
  norm=$(printf '%s' "$raw" | tr ',' ' ')
  local -a found=()
  for id in $norm; do
    [[ -z $id ]] && continue
    if ! registry_index "$id" >/dev/null; then
      echo "unknown tool: $id" >&2
      return 1
    fi
    found[${#found[@]}]=$id
  done
  if [[ ${#found[@]} -eq 0 ]]; then
    echo "no tools selected" >&2
    return 1
  fi
  local printed=""
  for id in $(printf '%s\n' "${found[@]}" | sort -u); do
    printf '%s\n' "$id"
    printed=1
  done
  [[ -n $printed ]]
}

save_selection() {
  local file tmp
  file=$(selection_file)
  mkdir -p "$(dirname -- "$file")"
  tmp=$(mktemp)
  printf '%s\n' "$@" | sed '/^$/d' | sort -u >"$tmp"
  if [[ ! -s $tmp ]]; then
    echo "no tools selected" >&2
    rm -f "$tmp"
    exit 1
  fi
  if [[ -f $file ]] && cmp -s "$tmp" "$file"; then
    rm -f "$tmp"
    return 0
  fi
  mv "$tmp" "$file"
}

dotfiles_self_test() {
  local sum sum2 s1 s2 backed fold
  SELF_TEST_TMP=$(mktemp -d)
  trap 'rm -rf "${SELF_TEST_TMP:-}"' EXIT
  local tmp="$SELF_TEST_TMP"
  export HOME="$tmp/home"
  export DOTFILES_SKIP_BREW=1
  unset DOTFILES_TOOLS_FILE || true
  mkdir -p "$HOME"
  registry_load
  local gidx zidx sidx
  gidx=$(registry_index ghostty)
  zidx=$(registry_index zsh)
  sidx=$(registry_index starship)
  if [[ ${reg_casks[$gidx]} != ghostty || -n ${reg_formulae[$gidx]} ]]; then
    echo "ghostty must be a cask" >&2
    exit 1
  fi
  if [[ ${reg_formulae[$sidx]} != starship || -n ${reg_casks[$sidx]} ]]; then
    echo "starship must be a formula" >&2
    exit 1
  fi
  if [[ ${reg_depends[$zidx]} != starship || -n ${reg_casks[$zidx]} ]]; then
    echo "zsh must depend on starship" >&2
    exit 1
  fi

  sum=$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$ROOT/starship/.config/starship.toml")

  dotfiles_snapshot >"$tmp/before.txt"
  dotfiles_apply starship
  if ! dotfiles_verify --before "$tmp/before.txt" starship; then
    echo "verify rejected a starship-only install" >&2
    exit 1
  fi
  same_file "$HOME/.config/starship.toml" "$ROOT/starship/.config/starship.toml"
  if [[ -e "$HOME/.config/nvim/init.lua" || -e "$HOME/.zshrc" || -e "$HOME/.config/ghostty/config" ]]; then
    echo "subset linked an unselected package" >&2
    exit 1
  fi
  s1=$(dotfiles_snapshot)
  dotfiles_apply starship
  s2=$(dotfiles_snapshot)
  if [[ $s1 != "$s2" ]]; then
    echo "second apply changed the tree" >&2
    printf '%s\n' "$s1" >"$tmp/s1"
    printf '%s\n' "$s2" >"$tmp/s2"
    diff -u "$tmp/s1" "$tmp/s2" >&2 || true
    exit 1
  fi

  rm -f "$HOME/.config/starship.toml"
  echo keep-me >"$HOME/.config/starship.toml"
  dotfiles_apply starship
  same_file "$HOME/.config/starship.toml" "$ROOT/starship/.config/starship.toml"
  backed=0
  while IFS= read -r path; do
    if grep -q keep-me "$path"; then
      backed=1
    fi
  done < <(find "$HOME/.local/share/dotfiles/backups" -name starship.toml -type f)
  if [[ $backed -ne 1 ]]; then
    echo "existing config was not backed up" >&2
    exit 1
  fi
  sum2=$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$ROOT/starship/.config/starship.toml")
  if [[ $sum != "$sum2" ]]; then
    echo "apply modified the repo package" >&2
    exit 1
  fi

  dotfiles_apply zsh
  same_file "$HOME/.zshrc" "$ROOT/zsh/.zshrc"
  same_file "$HOME/.config/starship.toml" "$ROOT/starship/.config/starship.toml"

  if (trap - EXIT; dotfiles_apply not-a-tool); then
    echo "unknown tool was accepted" >&2
    exit 1
  fi

  fold="$tmp/foldhome"
  mkdir -p "$fold"
  HOME="$fold"
  ln -s "$ROOT/nvim/.config" "$HOME/.config"
  dotfiles_apply starship
  same_file "$HOME/.config/starship.toml" "$ROOT/starship/.config/starship.toml"
  same_file "$HOME/.config/nvim/init.lua" "$ROOT/nvim/.config/nvim/init.lua"
  if ! find "$HOME/.local/share/dotfiles/backups" -name .config -type l | grep -q .; then
    echo "folded config was not backed up" >&2
    exit 1
  fi

  if command -v chezmoi >/dev/null 2>&1; then
    rm -rf "$HOME"
    mkdir -p "$HOME"
    "$ROOT/setup" --tools starship --yes
    same_file "$HOME/.config/starship.toml" "$ROOT/starship/.config/starship.toml"
    if [[ -e $HOME/.zshrc ]]; then
      echo "setup linked an unselected package" >&2
      exit 1
    fi
    if ! grep -qx starship "$HOME/.config/dotfiles/tools"; then
      echo "selection was not remembered" >&2
      exit 1
    fi
    s1=$(dotfiles_snapshot)
    local sel_mtime
    sel_mtime=$(mtime_ns "$HOME/.config/dotfiles/tools")
    "$ROOT/setup" --yes
    s2=$(dotfiles_snapshot)
    if [[ $s1 != "$s2" ]]; then
      echo "second setup changed the tree" >&2
      exit 1
    fi
    if [[ $(mtime_ns "$HOME/.config/dotfiles/tools") != "$sel_mtime" ]]; then
      echo "second setup rewrote the saved selection" >&2
      exit 1
    fi
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  case ${1:-} in
    apply)
      shift
      dotfiles_apply "$@"
      ;;
    snapshot)
      dotfiles_snapshot
      ;;
    verify)
      shift
      dotfiles_verify "$@"
      ;;
    self-test)
      dotfiles_self_test
      ;;
    *)
      echo "usage: lib/dotfiles.sh apply|snapshot|verify|self-test" >&2
      exit 2
      ;;
  esac
fi
