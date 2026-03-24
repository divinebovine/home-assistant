#!/usr/bin/env bash
# deploy.sh — Push HA config files from laptop to HA machine and reload
#
# Usage:
#   ./deploy.sh
#
# Requirements:
#   HA_URL      — Home Assistant base URL (e.g. http://homeassistant.local:8123)
#   HA_TOKEN    — Long-lived access token from your HA profile
#   HA_SSH_HOST — Hostname or IP of the HA machine (e.g. homeassistant.local)
#   HA_SSH_USER — SSH user (default: root)
#   HA_SSH_PORT — SSH port (default: 22)

set -euo pipefail

HA_URL="${HA_URL:-http://homeassistant.local:8123}"
HA_TOKEN="${HA_TOKEN:?HA_TOKEN environment variable is required}"
HA_SSH_HOST="${HA_SSH_HOST:?HA_SSH_HOST environment variable is required}"
HA_SSH_USER="${HA_SSH_USER:-root}"
HA_SSH_PORT="${HA_SSH_PORT:-22}"
CONFIG_DIR="/config"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

DIRS=(automations input_boolean input_number input_text timers blueprints lovelace)

SSH_OPTS=(-p "$HA_SSH_PORT" -o StrictHostKeyChecking=no -o BatchMode=yes)
RSYNC_OPTS=(-az --delete -e "ssh ${SSH_OPTS[*]}")

# ── 1. Create a backup via SSH ───────────────────────────────────────────────
echo "Creating backup (this may take a minute)..."
backup_response=$(ssh "${SSH_OPTS[@]}" "${HA_SSH_USER}@${HA_SSH_HOST}" \
  "ha backups new --name 'pre-deploy $(date '+%Y-%m-%d %H:%M')' --raw-json" || true)

backup_slug=$(echo "$backup_response" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4 || true)
if [ -z "$backup_slug" ]; then
  echo "Backup FAILED or could not be verified — aborting deploy."
  echo "Response: $backup_response"
  exit 1
fi
echo "Backup complete (slug: $backup_slug)."

# ── 2. Push files via rsync ───────────────────────────────────────────────────
echo "Ensuring rsync is available on remote..."
ssh "${SSH_OPTS[@]}" "${HA_SSH_USER}@${HA_SSH_HOST}" \
  "which rsync > /dev/null 2>&1 || apk add rsync --no-cache -q"

echo "Pushing config files to ${HA_SSH_USER}@${HA_SSH_HOST}:${CONFIG_DIR}..."
for dir in "${DIRS[@]}"; do
  src="$REPO_DIR/$dir"
  dst="${HA_SSH_USER}@${HA_SSH_HOST}:${CONFIG_DIR}/${dir}"
  if [ -d "$src" ]; then
    rsync "${RSYNC_OPTS[@]}" "$src/" "$dst"
    echo "  ✓ $dir"
  else
    echo "  - $dir (not found in repo, skipped)"
  fi
done

# ── 3. Check config ───────────────────────────────────────────────────────────
echo ""
echo "Running configuration check..."
response=$(curl -sf \
  -X POST "$HA_URL/api/config/core/check_config" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json")

result=$(echo "$response" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
errors=$(echo "$response" | grep -o '"errors":[^,}]*' | cut -d: -f2-)

if [ "$result" != "valid" ]; then
  echo "Config check FAILED: $errors"
  echo "Files have already been pushed — fix the error and re-deploy, or restore from the HA backup."
  exit 1
fi
echo "Config check passed."

# ── 4. Reload HA domains ──────────────────────────────────────────────────────
echo ""
echo "Reloading..."
domains=(automation input_boolean input_number input_text timer)
for domain in "${domains[@]}"; do
  curl -sf \
    -X POST "$HA_URL/api/services/$domain/reload" \
    -H "Authorization: Bearer $HA_TOKEN" \
    -H "Content-Type: application/json" \
    -o /dev/null
  echo "  ✓ $domain"
done

echo ""
echo "Done."
