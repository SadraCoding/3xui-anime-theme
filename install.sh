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

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "ERROR: Please run as root (use sudo)."
    exit 1
  fi
}

need_deps() {
  echo "[+] Installing dependencies..."
  apt update && apt install -y git ca-certificates build-essential golang curl
  if ! command -v node &>/dev/null; then
    echo "[+] Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
  fi
  if ! command -v npm &>/dev/null; then
    echo "[+] Installing npm..."
    apt install -y npm
  fi
}

get_theme_frontend() {
  # First try: running from cloned repo
  if [[ -d "./${FRONTEND_DIR}" ]]; then
    echo "$(pwd)/${FRONTEND_DIR}"
    return
  fi
  
  # Second try: script directory
  local script_dir
  script_dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
  if [[ -d "${script_dir}/${FRONTEND_DIR}" ]]; then
    echo "${script_dir}/${FRONTEND_DIR}"
    return
  fi
  
  # Third: clone theme repo
  echo "[+] Downloading theme frontend from GitHub..."
  git clone --depth 1 "${REPO_THEME}" "${WORKDIR}/theme"
  echo "${WORKDIR}/theme/${FRONTEND_DIR}"
}

backup_current() {
  mkdir -p "${BACKUP_DIR}"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  local backup="${BACKUP_DIR}/x-ui.bak.${ts}"
  cp "${BIN}" "${backup}"
  echo "[+] Backup saved: ${backup}"
  echo "${backup}" > "${BACKUP_DIR}/latest_backup"
}

restore_backup() {
  local backup="${1:-$(cat "${BACKUP_DIR}/latest_backup" 2>/dev/null)}"
  if [[ ! -f "${backup}" ]]; then
    echo "ERROR: Backup not found: ${backup}"
    echo "Available backups:"
    ls -lt "${BACKUP_DIR}"/x-ui.bak.* 2>/dev/null | head -5 || true
    exit 1
  fi
  systemctl stop "${SERVICE}" || true
  cp "${backup}" "${BIN}"
  chmod 755 "${BIN}"
  systemctl start "${SERVICE}" || true
  echo "[+] Restored: ${backup}"
}

main() {
  need_root

  local cmd="${1:-install}"

  case "${cmd}" in
    install)
      echo "============================================"
      echo "  3x-ui Anime Theme Installer"
      echo "  SadraCoding/3xui-anime-theme"
      echo "============================================"

      need_deps

      rm -rf "${WORKDIR}"
      mkdir -p "${WORKDIR}"

      # Get theme frontend
      THEME_FRONTEND="$(get_theme_frontend)"

      # Clone main 3x-ui
      echo "[+] Cloning 3x-ui..."
      git clone --depth 1 "${REPO_MAIN}" "${WORKDIR}/3x-ui"

      # Replace frontend
      echo "[+] Replacing frontend with anime theme..."
      rm -rf "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
      cp -r "${THEME_FRONTEND}" "${WORKDIR}/3x-ui/${FRONTEND_DIR}"

      # Build frontend
      echo "[+] Building frontend (npm)..."
      cd "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
      npm install
      npm run build

      # Build backend
      echo "[+] Building backend (Go)..."
      cd "${WORKDIR}/3x-ui"
      go build -ldflags "-w -s" -o x-ui-custom main.go

      # Backup & install
      echo "[+] Backing up current x-ui..."
      backup_current

      echo "[+] Installing new x-ui..."
      systemctl stop "${SERVICE}" || true
      install -m 0755 x-ui-custom "${BIN}"
      systemctl start "${SERVICE}" || true

      echo ""
      echo "[+] Done! Anime theme installed."
      echo "[+] Open your panel to see the theme."
      ;;

    uninstall)
      echo "[+] Restoring backup..."
      restore_backup
      echo "[+] Original panel restored."
      ;;

    status)
      systemctl status "${SERVICE}" --no-pager || true
      echo ""
      echo "Backups:"
      ls -lt "${BACKUP_DIR}"/x-ui.bak.* 2>/dev/null | head -5 || echo "No backups found"
      ;;

    *)
      echo "Usage: $0 {install|uninstall|status}"
      exit 1
      ;;
  esac
}

main "$@"