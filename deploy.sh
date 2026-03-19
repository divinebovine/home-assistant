#!/usr/bin/env bash
# deploy.sh — Copy HA config files and reload after a config check
#
# Usage:
#   ./deploy.sh
#
# Requirements:
#   HA_URL   — Home Assistant base URL (e.g. http://localhost:8123)
#   HA_TOKEN — Long-lived access token from your HA profile

set -euo pipefail

HA_URL="${HA_URL:-http://localhost:8123}"
HA_TOKEN="${HA_TOKEN:?HA_TOKEN environment variable is required}"
CONFIG_DIR="/root/config"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$(mktemp -d)"

DIRS=(automations input_boolean input_number input_text timers blueprints lovelace)

# ── 1. Back up existing config ────────────────────────────────────────────────
echo "Backing up existing config to $BACKUP_DIR..."
for dir in "${DIRS[@]}"; do
  src="$CONFIG_DIR/$dir"
  if [ -d "$src" ]; then
    cp -r "$src" "$BACKUP_DIR/$dir"
    echo "  ✓ $dir"
  fi
done

restore_backup() {
  echo ""
  echo "Restoring backup..."
  for dir in "${DIRS[@]}"; do
    src="$BACKUP_DIR/$dir"
    dst="$CONFIG_DIR/$dir"
    if [ -d "$src" ]; then
      rm -rf "$dst"
      cp -r "$src" "$dst"
      echo "  ✓ $dir"
    fi
  done
  rm -rf "$BACKUP_DIR"
  echo "Backup restored. No changes were applied."
}

# ── 2. Copy new files ─────────────────────────────────────────────────────────
echo ""
echo "Copying config files from $REPO_DIR to $CONFIG_DIR..."
for dir in "${DIRS[@]}"; do
  src="$REPO_DIR/$dir"
  dst="$CONFIG_DIR/$dir"
  if [ -d "$src" ]; then
    if [ ! -d "$dst" ]; then
      mkdir -p "$dst"
      echo "  + $dir (created)"
    fi
    rm -rf "$dst"
    cp -r "$src" "$dst"
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
  restore_backup
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

# ── 5. Clean up backup ────────────────────────────────────────────────────────
rm -rf "$BACKUP_DIR"
echo ""
echo "Done."
