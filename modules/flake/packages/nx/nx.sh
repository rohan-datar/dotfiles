#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

die() {
  echo "nx: $*" >&2
  exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }

# --- Flake root (env or git toplevel or cwd)
FLAKE="${FLAKE:-$(
  git rev-parse --show-toplevel 2>/dev/null || pwd
)}"

OS="$(uname -s)"
case "$OS" in
Linux) os_label="NixOS" ;;
Darwin) os_label="macOS" ;;
*) die "Unsupported OS: $OS" ;;
esac

# --- Formatting: prefer `nix fmt` (flake's formatter). Fallback: run nixfmt on each file.
format_repo() {
  if ! nix fmt "${FLAKE}" >/dev/null 2>&1; then
    echo "nx: nix fmt unavailable or failed; falling back to nixfmt"
    # Pure-POSIX fallback: format each .nix file in-place without relying on nixfmt flags
    while IFS= read -r -d '' f; do
      tmp="$(mktemp)"
      if nixfmt "$f" >"$tmp"; then
        mv "$tmp" "$f"
      else
        rm -f "$tmp"
        echo "nx: nixfmt failed on $f"
        exit 1
      fi
    done < <(find "${FLAKE}" -type f -name '*.nix' -print0)
  fi
}

# --- Flake check: mode=warn (default) or require (exit on failure)
flake_check() {
  local mode="${1:-warn}"
  [[ ${NX_SKIP_CHECK:-0} == "1" ]] && return 0

  local check_args=""

  # Only check relevant configurations for the current platform
  if [[ $OS == "Darwin" ]]; then
    check_args+=" --no-build --keep-going .#darwinConfigurations.*"
  elif [[ $OS == "Linux" ]]; then
    check_args+=" --no-build --keep-going .#nixosConfigurations.*"
  fi

  if ! nix flake check "${check_args}"; then
    echo "nx: flake check failed"
    if [[ $mode == "require" ]]; then
      exit 1
    else
      true
    fi
  fi
}

# --- Current generation numbers from profile symlinks
system_gen() {
  local link base gen
  link="$(readlink /nix/var/nix/profiles/system 2>/dev/null || true)" || true
  if [[ -n ${link:-} ]]; then
    base="${link##*/}" # system-123-link
    gen="${base#system-}"
    gen="${gen%-link}"
    printf "%s" "${gen}"
  fi
}

do_switch() {
  local action="${1:-switch}"
  pushd "$FLAKE" >/dev/null
  trap 'popd >/dev/null' RETURN

  format_repo
  # warn-only here (can be skipped with NX_SKIP_CHECK=1)
  if [[ ${NX_SKIP_CHECK:-0} != "1" ]]; then flake_check warn; fi

  if have nh; then
    if [[ $OS == "Linux" ]]; then
      nh os switch . -H "${NIX_CONFIG_NAME}"
    else
      nh darwin switch . -H "${NIX_CONFIG_NAME}"
    fi
  else
    if [[ $OS == "Linux" ]]; then
      sudo nixos-rebuild switch --flake .#"${NIX_CONFIG_NAME}"
    else
      darwin-rebuild switch --flake .#"${NIX_CONFIG_NAME}"
    fi
  fi

  # Optional desktop ping on Linux
  if [[ $OS == "Linux" ]] && have notify-send; then
    notify-send -e "Rebuild OK" "System & Home-Manager applied"
  fi

  # Commit only if repo actually changed
  git add -A
  if git diff --cached --quiet; then
    echo "nx: nothing to commit (repo unchanged)"
    return 0
  fi

  local sys stamp host msg
  sys="$(system_gen || true)"
  # Portable ISO8601 (UTC) for uutils/BSD/GNU
  stamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  host="$(hostname)"
  msg="nx ${action} (${host}/${os_label}): sys=${sys:-?} @ ${stamp}"

  git --no-pager diff --cached -U0 || true
  git commit -m "$msg" || true
}

do_update() {
  pushd "$FLAKE" >/dev/null
  trap 'popd >/dev/null' RETURN

  # Pre-update sanity (warn-only)
  flake_check warn

  git pull --rebase --autostash --ff-only || true
  nix flake update

  # Post-update must pass before switching
  flake_check warn

  # Switch; avoid duplicate check here
  NX_SKIP_CHECK=1 do_switch update
}

usage() {
  cat <<USAGE
Usage: nx <command>

Commands (aliases):
  switch, s     Format, check (warn), rebuild OS+HM, commit if repo changed
  update, u     Pull; update lock; check (require); then 'switch'
  help, h       Show this help

Env:
  FLAKE   Path to your flake (default: git toplevel or cwd)
  NX_SKIP_CHECK=1      Skip 'nix flake check' entirely
USAGE
}

cmd="${1:-switch}"
shift || true
case "$cmd" in
switch | s) do_switch "$@" ;;
update | u) do_update "$@" ;;
help | h | --help | -h) usage ;;
*)
  usage
  exit 1
  ;;
esac
