#!/usr/bin/env bash
set -e

# ============================================================
#  3x-ui Anime Theme - Quick Apply
#  Repo: SadraCoding/3xui-anime-theme
# ============================================================

XUI_DIR="/usr/local/x-ui"
BACKUP_DIR="/etc/x-ui/theme-backup"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[-]${NC} $1"; exit 1; }

# Check root
[[ "${EUID:-$(id -u)}" -ne 0 ]] && err "Please run as root (use sudo)."

# Check if x-ui exists
[[ ! -f "${XUI_DIR}/x-ui" ]] && err "x-ui not found at ${XUI_DIR}. Install 3x-ui first."

# Find dist folder
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"

if [[ ! -d "${DIST_DIR}" ]]; then
    err "dist folder not found! Make sure you're in the theme repo directory."
fi

# Backup original dist
if [[ -d "${XUI_DIR}/web/dist" ]]; then
    mkdir -p "${BACKUP_DIR}"
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    cp -r "${XUI_DIR}/web/dist" "${BACKUP_DIR}/dist.bak.${ts}"
    log "Backup saved to ${BACKUP_DIR}/dist.bak.${ts}"
fi

# Apply theme
log "Applying anime theme..."
systemctl stop x-ui 2>/dev/null || true
rm -rf "${XUI_DIR}/web/dist"
cp -r "${DIST_DIR}" "${XUI_DIR}/web/dist"
systemctl start x-ui 2>/dev/null || true

# Check service
sleep 1
if systemctl is-active --quiet x-ui 2>/dev/null; then
    log "x-ui is running with anime theme!"
else
    warn "x-ui may not have started. Check: systemctl status x-ui"
fi

echo ""
echo "============================================"
echo "  Anime Theme Applied Successfully!"
echo "  SadraCoding/3xui-anime-theme"
echo "============================================"
echo ""
echo -e "${YELLOW}Clear browser cache: Ctrl+Shift+R${NC}"
echo ""
echo "To restore original: backup is at ${BACKUP_DIR}/"