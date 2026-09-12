set positional-arguments
set shell := ["bash", "-euo", "pipefail", "-c"]
set script-interpreter := ["bash", "-euo", "pipefail"]

export FLAKE_DIR := justfile_directory()
export JUST_BIN := just_executable()
export JUST_JUSTFILE := justfile()

# List workflows
default:
    @"$JUST_BIN" --list

# Format all files with the flake's treefmt formatter
fmt:
    nix fmt "$FLAKE_DIR" >/dev/null

# Check flake evaluation; require (default) or warn on failure
[script]
check mode='require':
    mode="${1:-require}"
    if [ "${SKIP_CHECK:-0}" = "1" ]; then
      exit 0
    fi
    if ! nix flake check -L "$FLAKE_DIR" --no-build --keep-going; then
      echo "just: flake check failed" >&2
      [ "$mode" = "require" ] || exit 0
      exit 1
    fi

# Rebuild and switch the current system (nh preferred)
[script]
rebuild:
    os="$(uname -s)"
    case "$os" in
      Linux)
        if command -v nh >/dev/null 2>&1; then
          nh os switch "$FLAKE_DIR"
        else
          sudo nixos-rebuild switch --flake "$FLAKE_DIR"
        fi
        if command -v notify-send >/dev/null 2>&1; then
          notify-send -e "Rebuild OK" "System & Home-Manager applied" || true
        fi
        ;;
      Darwin)
        if command -v nh >/dev/null 2>&1; then
          nh darwin switch "$FLAKE_DIR"
        else
          darwin-rebuild switch --flake "$FLAKE_DIR"
        fi
        ;;
      *)
        echo "just: unsupported OS: $os" >&2
        exit 1
        ;;
    esac

# Commit all repo changes with a standardized message
[script]
commit action='change':
    action="${1:-change}"
    os="$(uname -s)"
    case "$os" in
      Linux) os_label="NixOS" ;;
      Darwin) os_label="macOS" ;;
      *)
        echo "just: unsupported OS: $os" >&2
        exit 1
        ;;
    esac
    git add -A
    if git diff --cached --quiet; then
      echo "just: nothing to commit (repo unchanged)"
      exit 0
    fi
    sys="$(readlink /nix/var/nix/profiles/system 2>/dev/null || true)"
    if [ -n "$sys" ]; then
      gen="${sys##*/}"
      gen="${gen#system-}"
      gen="${gen%-link}"
    else
      gen="?"
    fi
    stamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    host="$(hostname -s)"
    msg="nix ${action} (${host}/${os_label}): sys=${gen} @ ${stamp}"
    git --no-pager diff --cached -U0 || true
    git commit -m "$msg"

# Format, check (warn), rebuild, and commit
switch: (_switch "switch")

# Pull, update the lock, check (require), then switch
[script]
update:
    "$JUST_BIN" check warn
    git pull --rebase --autostash --ff-only || true
    nix flake update --flake "$FLAKE_DIR"
    "$JUST_BIN" check require
    "$JUST_BIN" _switch update

# Garbage-collect and optimise the store, keeping N generations (default 3)
[script]
clean keep='3':
    keep="${1:-3}"
    case "$keep" in
      '' | *[!0-9]*)
        echo "just: clean: expected a generation count, got '$keep'" >&2
        exit 1
        ;;
    esac
    if ! command -v nh >/dev/null 2>&1; then
      echo "just: clean: requires nh, which is not on PATH" >&2
      exit 1
    fi
    nh clean all --keep "$keep" --keep-one --optimise

[private]
[script]
_switch action='switch':
    action="${1:-switch}"
    if ! "$JUST_BIN" fmt; then
      echo "just: nix fmt failed (continuing)" >&2
    fi
    if [ "$action" != "update" ]; then
      "$JUST_BIN" check warn
    fi
    "$JUST_BIN" rebuild
    if ! "$JUST_BIN" commit "$action"; then
      echo "just: commit failed; the rebuild was already applied" >&2
    fi
