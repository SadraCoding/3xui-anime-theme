#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  3x-ui Anime Theme Installer
#  Repo: SadraCoding/3xui-anime-theme
# ============================================================

REPO_MAIN="https://github.com/MHSanaei/3x-ui.git"
REPO_THEME="https://github.com/SadraCoding/3xui-anime-theme.git"
FRONTEND_DIR="frontend"

INSTALL_DIR="/usr/local/x-ui"
BIN="${INSTALL_DIR}/x-ui"
SERVICE="x-ui"

WORKDIR="/root/3xui-theme-build"
BACKUP_DIR="/etc/x-ui/theme-backups"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[-]${NC} $1"; exit 1; }

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    err "Please run as root (use sudo)."
  fi
}

install_nodejs() {
  local required_major=20
  
  # Check if Node.js is installed and version is enough
  if command -v node &>/dev/null; then
    local current_ver
    current_ver=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ "$current_ver" -ge "$required_major" ]]; then
      log "Node.js $(node -v) already installed."
      return
    fi
    warn "Node.js $(node -v) is too old. Upgrading..."
    apt remove nodejs -y 2>/dev/null || true
    apt autoremove -y 2>/dev/null || true
  fi

  log "Installing Node.js 22.x..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt install -y nodejs
  
  log "Node.js $(node -v) installed."
  log "npm $(npm -v) installed."
}

need_deps() {
  log "Updating package lists..."
  apt update -qq
  
  log "Installing system dependencies..."
  apt install -y git ca-certificates build-essential golang curl
  
  install_nodejs
}

backup_current() {
  if [[ ! -f "${BIN}" ]]; then
    warn "No existing x-ui binary found at ${BIN}, skipping backup."
    return
  fi
  
  mkdir -p "${BACKUP_DIR}"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  local backup="${BACKUP_DIR}/x-ui.bak.${ts}"
  cp "${BIN}" "${backup}"
  log "Backup saved: ${backup}"
  echo "${backup}" > "${BACKUP_DIR}/latest_backup"
}

restore_backup() {
  local backup="${1:-$(cat "${BACKUP_DIR}/latest_backup" 2>/dev/null)}"
  if [[ ! -f "${backup}" ]]; then
    err "Backup not found: ${backup}"
  fi
  
  log "Stopping ${SERVICE}..."
  systemctl stop "${SERVICE}" 2>/dev/null || true
  
  log "Restoring backup..."
  cp "${backup}" "${BIN}"
  chmod 755 "${BIN}"
  
  log "Starting ${SERVICE}..."
  systemctl start "${SERVICE}" 2>/dev/null || true
  
  log "Restored: ${backup}"
}

check_command() {
  if ! command -v "$1" &>/dev/null; then
    err "$1 is not installed. Something went wrong."
  fi
}

main() {
  need_root
  local cmd="${1:-install}"

  case "${cmd}" in
    install)
      clear
      echo "============================================"
      echo "  3x-ui Anime Theme Installer"
      echo "  SadraCoding/3xui-anime-theme"
      echo "============================================"
      echo ""
      
      # Install dependencies
      need_deps
      
      # Verify tools
      check_command git
      check_command go
      check_command node
      check_command npm
      
      # Clean workdir
      rm -rf "${WORKDIR}"
      mkdir -p "${WORKDIR}"
      
      # Clone theme repo
      log "Downloading anime theme..."
      git clone --depth 1 "${REPO_THEME}" "${WORKDIR}/theme"
      
      if [[ ! -d "${WORKDIR}/theme/${FRONTEND_DIR}" ]]; then
        err "Theme frontend folder not found in cloned repo!"
      fi
      
      # Clone main 3x-ui
      log "Cloning 3x-ui..."
      git clone --depth 1 "${REPO_MAIN}" "${WORKDIR}/3x-ui"
      
      # Replace frontend
      log "Replacing frontend with anime theme..."
      rm -rf "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
      cp -r "${WORKDIR}/theme/${FRONTEND_DIR}" "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
      
      # Build frontend
      log "Building frontend (this may take a few minutes)..."
      cd "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
      npm install --silent
      npm run build
      
      if [[ ! -d "${WORKDIR}/3x-ui/web/dist" ]]; then
        err "Frontend build failed! web/dist folder not found."
      fi
      
      log "Frontend built successfully."
      
      # Build backend
      log "Building backend (Go)..."
      cd "${WORKDIR}/3x-ui"
      go build -ldflags "-w -s" -o x-ui-custom main.go
      
      if [[ ! -f "x-ui-custom" ]]; then
        err "Backend build failed!"
      fi
      
      log "Backend built successfully."
      
      # Backup current installation
      backup_current
      
      # Install new binary
      log "Installing new x-ui..."
      systemctl stop "${SERVICE}" 2>/dev/null || true
      install -m 0755 x-ui-custom "${BIN}"
      systemctl start "${SERVICE}" 2>/dev/null || true
      
      # Verify service started
      sleep 2
      if systemctl is-active --quiet "${SERVICE}"; then
        log "Service ${SERVICE} is running."
      else
        warn "Service ${SERVICE} may not have started. Check: systemctl status ${SERVICE}"
      fi
      
      echo ""
      echo "============================================"
      echo "  Installation Complete!"
      echo "  Anime theme is now active on your panel."
      echo "  SadraCoding/3xui-anime-theme"
      echo "============================================"
      echo ""
      echo "To uninstall: $0 uninstall"
      echo "To check status: $0 status"
      ;;
      
    uninstall)
      log "Restoring original x-ui..."
      restore_backup
      log "Original panel restored."
      ;;
      
    status)
      echo "Service status:"
      systemctl status "${SERVICE}" --no-pager 2>/dev/null || echo "Service ${SERVICE} not found."
      echo ""
      echo "Available backups:"
      if [[ -d "${BACKUP_DIR}" ]]; then
        ls -lth "${BACKUP_DIR}"/x-ui.bak.* 2>/dev/null | head -10 || echo "No backups found."
      else
        echo "No backup directory found."
      fi
      ;;
      
    *)
      echo "Usage: $0 {install|uninstall|status}"
      exit 1
      ;;
  esac
}

main "$@"