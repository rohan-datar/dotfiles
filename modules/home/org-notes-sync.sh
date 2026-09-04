# shellcheck shell=bash
set -euo pipefail

: "${ORG_SYNC_HOST_ID:?ORG_SYNC_HOST_ID is required}"
: "${ORG_SYNC_NOTES_DIR:?ORG_SYNC_NOTES_DIR is required}"
: "${ORG_SYNC_SSH_KEY_FILE:?ORG_SYNC_SSH_KEY_FILE is required}"
: "${ORG_SYNC_RCLONE_CONFIG:?ORG_SYNC_RCLONE_CONFIG is required}"
: "${ORG_SYNC_RCLONE_FILTER:?ORG_SYNC_RCLONE_FILTER is required}"
: "${ORG_SYNC_KNOWN_HOSTS:?ORG_SYNC_KNOWN_HOSTS is required}"
: "${ORG_SYNC_INITIAL_SOURCE:?ORG_SYNC_INITIAL_SOURCE is required}"
: "${ORG_SYNC_STORAGE_BOX_USER:?ORG_SYNC_STORAGE_BOX_USER is required}"

readonly remote_name="org-storage-box"
readonly remote_notes="${remote_name}:/home/org"
readonly remote_lock="/home/.org-notes-sync.lock"
readonly storage_box_host="${ORG_SYNC_STORAGE_BOX_USER}.your-storagebox.de"
readonly state_dir="${HOME}/.local/state/rclone/org-sync/${ORG_SYNC_HOST_ID}"
readonly work_dir="${state_dir}/work"
readonly local_lock="${state_dir}/process.lock"
readonly initialized_marker="${state_dir}/initialized"
readonly local_backup_root="${HOME}/.local/share/org-sync/backups/${ORG_SYNC_HOST_ID}"
readonly stale_after=43200

mkdir -p "${state_dir}" "${work_dir}" "${local_backup_root}" "${ORG_SYNC_NOTES_DIR}"

rclone_cmd=(rclone --config "${ORG_SYNC_RCLONE_CONFIG}")
sftp_cmd=(
  sftp -q -P 23 -i "${ORG_SYNC_SSH_KEY_FILE}" -o BatchMode=yes
  -o "UserKnownHostsFile=${ORG_SYNC_KNOWN_HOSTS}"
  -o StrictHostKeyChecking=yes -o HostKeyAlgorithms=ssh-ed25519
)

tmp_dir="$(mktemp -d)"
local_locked=0
remote_locked=0
lock_token=""

file_mtime() {
  stat -c %Y "$1" 2>/dev/null || printf '0\n'
}

sftp_batch() {
  "${sftp_cmd[@]}" -b "$1" "${ORG_SYNC_STORAGE_BOX_USER}@${storage_box_host}"
}

release_remote_lock() {
  [[ "${remote_locked}" == 1 ]] || return 0
  local owner_file="${tmp_dir}/owner-current"
  printf 'get %s/owner %s\n' "${remote_lock}" "${owner_file}" >"${tmp_dir}/get-owner.batch"
  if sftp_batch "${tmp_dir}/get-owner.batch" >/dev/null 2>&1 \
      && [[ "$(cat "${owner_file}")" == "${lock_token}" ]]; then
    printf 'rm %s/owner\nrmdir %s\n' "${remote_lock}" "${remote_lock}" >"${tmp_dir}/release.batch"
    sftp_batch "${tmp_dir}/release.batch" >/dev/null 2>&1 || true
  fi
  remote_locked=0
}

cleanup() {
  release_remote_lock
  if [[ "${local_locked}" == 1 ]]; then
    rm -rf "${local_lock}"
  fi
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT INT TERM

acquire_local_lock() {
  if mkdir "${local_lock}" 2>/dev/null; then
    local_locked=1
    date +%s >"${local_lock}/started"
    return 0
  fi

  local started now
  started="$(file_mtime "${local_lock}")"
  now="$(date +%s)"
  if [[ "${started}" =~ ^[0-9]+$ ]] && (( now - started > stale_after )); then
    echo "Removing stale local lock older than 12 hours." >&2
    rm -rf "${local_lock}"
    mkdir "${local_lock}"
    local_locked=1
    date +%s >"${local_lock}/started"
    return 0
  fi

  echo "Another local Org sync or snapshot process is active; skipping." >&2
  return 1
}

try_acquire_remote_lock() {
  printf 'mkdir %s\n' "${remote_lock}" >"${tmp_dir}/acquire.batch"
  if ! sftp_batch "${tmp_dir}/acquire.batch" >/dev/null 2>&1; then
    return 1
  fi

  local epoch owner_file
  epoch="$(date +%s)"
  lock_token="${ORG_SYNC_HOST_ID}:$$:${epoch}"
  owner_file="${tmp_dir}/owner-local"
  printf '%s' "${lock_token}" >"${owner_file}"
  printf 'put %s %s/owner\n' "${owner_file}" "${remote_lock}" >"${tmp_dir}/put-owner.batch"
  if ! sftp_batch "${tmp_dir}/put-owner.batch" >/dev/null 2>&1; then
    printf 'rmdir %s\n' "${remote_lock}" >"${tmp_dir}/release-empty.batch"
    sftp_batch "${tmp_dir}/release-empty.batch" >/dev/null 2>&1 || true
    return 1
  fi
  remote_locked=1
}

acquire_remote_lock() {
  if try_acquire_remote_lock; then
    return 0
  fi

  local owner_file="${tmp_dir}/owner-remote" owner epoch now
  printf 'get %s/owner %s\n' "${remote_lock}" "${owner_file}" >"${tmp_dir}/get-stale.batch"
  if sftp_batch "${tmp_dir}/get-stale.batch" >/dev/null 2>&1; then
    owner="$(cat "${owner_file}")"
    epoch="${owner##*:}"
    now="$(date +%s)"
    if [[ "${epoch}" =~ ^[0-9]+$ ]] && (( now - epoch > stale_after )); then
      echo "Removing stale remote lock owned by ${owner}." >&2
      printf 'rm %s/owner\nrmdir %s\n' "${remote_lock}" "${remote_lock}" >"${tmp_dir}/break-stale.batch"
      sftp_batch "${tmp_dir}/break-stale.batch" >/dev/null 2>&1 || return 1
      try_acquire_remote_lock && return 0
    fi
  fi

  echo "Another computer holds the Org sync lock; skipping this run." >&2
  return 1
}

unlock_stale() {
  acquire_local_lock || exit 0
  local owner_file="${tmp_dir}/owner-unlock" owner epoch now
  printf 'get %s/owner %s\n' "${remote_lock}" "${owner_file}" >"${tmp_dir}/get-unlock.batch"
  if ! sftp_batch "${tmp_dir}/get-unlock.batch" >/dev/null 2>&1; then
    echo "No readable remote lock exists."
    return 0
  fi
  owner="$(cat "${owner_file}")"
  epoch="${owner##*:}"
  now="$(date +%s)"
  if [[ ! "${epoch}" =~ ^[0-9]+$ ]] || (( now - epoch <= stale_after )); then
    echo "Refusing to remove a lock younger than 12 hours: ${owner}" >&2
    return 1
  fi
  printf 'rm %s/owner\nrmdir %s\n' "${remote_lock}" "${remote_lock}" >"${tmp_dir}/unlock.batch"
  sftp_batch "${tmp_dir}/unlock.batch"
  echo "Removed stale remote lock: ${owner}"
}

run_bisync() {
  local mode="$1" timestamp local_backup remote_backup
  if [[ "${mode}" == run && ! -e "${initialized_marker}" ]]; then
    echo "Org bisync is not initialized. Run: org-notes-sync init" >&2
    return 0
  fi

  if [[ ! -e "${ORG_SYNC_NOTES_DIR}/RCLONE_TEST" ]]; then
    printf 'org-sync-access-check\n' >"${ORG_SYNC_NOTES_DIR}/RCLONE_TEST"
  fi
  acquire_local_lock || return 0
  acquire_remote_lock || return 0

  timestamp="$(date '+%Y%m%d-%H%M%S')"
  local_backup="${local_backup_root}/${timestamp}"
  remote_backup="${remote_name}:/home/.org-sync-backups/${ORG_SYNC_HOST_ID}/${timestamp}"
  "${rclone_cmd[@]}" mkdir "${remote_name}:/home/.org-sync-backups/${ORG_SYNC_HOST_ID}"

  args=(
    bisync "${ORG_SYNC_NOTES_DIR}" "${remote_notes}"
    --filter-from "${ORG_SYNC_RCLONE_FILTER}"
    --workdir "${work_dir}"
    --check-access --check-filename RCLONE_TEST
    --create-empty-src-dirs
    --compare "size,modtime" --modify-window 2s
    --conflict-resolve newer --conflict-loser pathname
    --conflict-suffix "conflict-${ORG_SYNC_HOST_ID}-${timestamp}"
    --max-delete 10 --max-lock 45m
    --resilient --recover --check-first
    --backup-dir1 "${local_backup}" --backup-dir2 "${remote_backup}"
    --transfers 4 --checkers 8
    --retries 3 --retries-sleep 10s --low-level-retries 10
    --contimeout 15s --timeout 1m
    --log-level INFO --stats-one-line
  )

  if [[ "${mode}" == init ]]; then
    args+=(--resync --resync-mode "${ORG_SYNC_INITIAL_SOURCE}")
  fi

  timeout 45m "${rclone_cmd[@]}" "${args[@]}"
  touch "${initialized_marker}"

  find "${local_backup_root}" -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf -- {} +
  "${rclone_cmd[@]}" delete "${remote_name}:/home/.org-sync-backups/${ORG_SYNC_HOST_ID}" \
    --min-age 30d --log-level NOTICE || true
  "${rclone_cmd[@]}" rmdirs "${remote_name}:/home/.org-sync-backups/${ORG_SYNC_HOST_ID}" \
    --leave-root --log-level NOTICE || true
}

case "${1:-run}" in
  run) run_bisync run ;;
  init) run_bisync init ;;
  unlock-stale) unlock_stale ;;
  *) echo "Usage: org-notes-sync [run|init|unlock-stale]" >&2; exit 2 ;;
esac
