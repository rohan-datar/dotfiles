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

# --- Formatting via the flake's own formatter (treefmt).
format_repo() {
  # stdout is noise on success, but stderr is deliberately left alone: formatting
  # failing is non-fatal, and it should never be silent.
  if ! nix fmt "${FLAKE}" >/dev/null; then
    echo "nx: nix fmt failed (continuing)" >&2
  fi
}

# --- Flake check: mode=warn (default) or require (exit on failure)
flake_check() {
  local mode="${1:-warn}"
  [[ ${NX_SKIP_CHECK:-0} == "1" ]] && return 0
  if ! nix flake check -L "${FLAKE}" --no-build --keep-going; then
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
      nh os switch .
    else
      nh darwin switch .
    fi
  else
    if [[ $OS == "Linux" ]]; then
      sudo nixos-rebuild switch --flake .
    else
      darwin-rebuild switch --flake .
    fi
  fi

  # Optional desktop ping on Linux
  if [[ $OS == "Linux" ]] && have notify-send; then
    notify-send -e "Rebuild OK" "System & Home-Manager applied" || true
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
  host="$(hostname -s)"
  msg="nx ${action} (${host}/${os_label}): sys=${sys:-?} @ ${stamp}"

  git --no-pager diff --cached -U0 || true
  # Non-fatal, but worth saying: the rebuild has already been applied at this point,
  # so a silent commit failure leaves the repo and the running system out of step.
  if ! git commit -m "$msg"; then
    echo "nx: commit failed; the rebuild was already applied" >&2
  fi
}

do_update() {
  pushd "$FLAKE" >/dev/null
  trap 'popd >/dev/null' RETURN

  # Pre-update sanity: warn only. A failure here predates the update, so it shouldn't
  # stop you pulling the very inputs that might fix it.
  flake_check warn

  git pull --rebase --autostash --ff-only || true
  nix flake update

  # Post-update must pass before switching. This is the check that decides whether the
  # new lock is safe to apply, so it's the one that blocks; NX_SKIP_CHECK=1 overrides.
  flake_check require

  # Switch; avoid duplicate check here
  NX_SKIP_CHECK=1 do_switch update
}

do_clean() {
  local keep="${1:-3}"
  [[ $keep =~ ^[0-9]+$ ]] || die "clean: expected a generation count, got '$keep'"
  # switch degrades to nixos-rebuild without nh; clean has no equivalent, so say so
  # plainly rather than dying with 'nh: command not found'.
  have nh || die "clean: requires nh, which is not on PATH"
  nh clean all --keep "$keep" --keep-one --optimise
}

usage() {
  cat <<USAGE
Usage: nx <command>

Commands (aliases):
  switch, s     Format, check (warn), rebuild OS+HM, commit if repo changed
  update, u     Pull; update lock; check (require); then 'switch'
  clean, c [N]  Garbage-collect and optimise the store, keeping N generations
                (default 3). Requires nh.
  help, h       Show this help

Env:
  FLAKE   Path to your flake (default: git toplevel or cwd)
  NX_SKIP_CHECK=1      Skip 'nix flake check' entirely
USAGE
}

cmd="${1:-switch}"
shift || true
case "$cmd" in
switch | s) do_switch switch ;;
update | u) do_update "$@" ;;
clean | c) do_clean "$@" ;;
help | h | --help | -h) usage ;;
*)
  usage
  exit 1
  ;;
esac
