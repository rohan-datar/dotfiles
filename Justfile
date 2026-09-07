set positional-arguments
set shell := ["bash", "-euo", "pipefail", "-c"]

export JUST_BIN := just_executable()
export JUST_FILE := justfile()

# List workflows
default:
    @"$JUST_BIN" --justfile "$JUST_FILE" --list

# Format all files with the flake's treefmt formatter
fmt:
    nix fmt "{{ justfile_directory() }}" >/dev/null

# Check flake evaluation; require (default) or warn on failure
check mode='require':
    #!/usr/bin/env bash
    set -euo pipefail
    mode="${1:-require}"
    if [ "${SKIP_CHECK:-0}" = "1" ]; then
      exit 0
    fi
    if ! nix flake check -L "{{ justfile_directory() }}" --no-build --keep-going; then
      echo "just: flake check failed" >&2
      [ "$mode" = "require" ] || exit 0
      exit 1
    fi

# Rebuild and switch the current system (nh preferred)
rebuild:
    #!/usr/bin/env bash
    set -euo pipefail
    os="$(uname -s)"
    case "$os" in
      Linux)
        if command -v nh >/dev/null 2>&1; then
          nh os switch "{{ justfile_directory() }}"
        else
          sudo nixos-rebuild switch --flake "{{ justfile_directory() }}"
        fi
        if command -v notify-send >/dev/null 2>&1; then
          notify-send -e "Rebuild OK" "System & Home-Manager applied" || true
        fi
        ;;
      Darwin)
        if command -v nh >/dev/null 2>&1; then
          nh darwin switch "{{ justfile_directory() }}"
        else
          darwin-rebuild switch --flake "{{ justfile_directory() }}"
        fi
        ;;
      *)
        echo "just: unsupported OS: $os" >&2
        exit 1
        ;;
    esac

# Commit all repo changes with a standardized message
commit action='change':
    #!/usr/bin/env bash
    set -euo pipefail
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
switch:
    "$JUST_BIN" --justfile "$JUST_FILE" _switch switch

# Pull, update the lock, check (require), then switch
update:
    #!/usr/bin/env bash
    set -euo pipefail
    "$JUST_BIN" --justfile "$JUST_FILE" check warn
    git pull --rebase --autostash --ff-only || true
    nix flake update "{{ justfile_directory() }}"
    "$JUST_BIN" --justfile "$JUST_FILE" check require
    "$JUST_BIN" --justfile "$JUST_FILE" _switch update

# Garbage-collect and optimise the store, keeping N generations (default 3)
clean keep='3':
    #!/usr/bin/env bash
    set -euo pipefail
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
_switch action='switch':
    #!/usr/bin/env bash
    set -euo pipefail
    action="${1:-switch}"
    if ! "$JUST_BIN" --justfile "$JUST_FILE" fmt; then
      echo "just: nix fmt failed (continuing)" >&2
    fi
    if [ "$action" != "update" ]; then
      "$JUST_BIN" --justfile "$JUST_FILE" check warn
    fi
    "$JUST_BIN" --justfile "$JUST_FILE" rebuild
    if ! "$JUST_BIN" --justfile "$JUST_FILE" commit "$action"; then
      echo "just: commit failed; the rebuild was already applied" >&2
    fi
