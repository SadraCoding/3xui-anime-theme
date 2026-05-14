#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  3x-ui Anime Theme Installer v2.1
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

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Helpers ───────────────────────────────────────────────

clear_screen() { clear; }

print_banner() {
    echo -e "${MAGENTA}"
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║       3x-ui Anime Theme Installer            ║"
    echo "  ║       SadraCoding/3xui-anime-theme           ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_line() {
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
}

log_info()  { echo -e "  ${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "  ${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "  ${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "  ${CYAN}[STEP]${NC}  $1"; }

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local answer
    
    if [[ "$default" == "y" ]]; then
        read -rp "  ${YELLOW}[?]${NC} ${prompt} [Y/n]: " answer
        answer="${answer:-y}"
    else
        read -rp "  ${YELLOW}[?]${NC} ${prompt} [y/N]: " answer
        answer="${answer:-n}"
    fi
    
    [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]
}

press_enter() {
    echo ""
    read -rp "  Press Enter to continue..." dummy
}

# ─── System Checks ────────────────────────────────────────

need_root() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        log_error "Please run as root (use sudo)."
        exit 1
    fi
}

check_xui_installed() {
    if [[ ! -f "${BIN}" ]]; then
        log_error "3x-ui not found at ${BIN}"
        echo ""
        log_info "Please install 3x-ui first:"
        echo "  bash <(curl -fsSL https://raw.githubusercontent.com/MHSanaei/3x-ui/main/install.sh)"
        exit 1
    fi
    local version
    version=$("${BIN}" version 2>/dev/null | head -1 || echo "unknown")
    log_info "3x-ui found: ${version}"
}

# ─── Dependency Installers ─────────────────────────────────

force_install_go() {
    log_step "Checking Go..."
    
    local required_major=22
    local need_install=false
    
    if ! command -v go &>/dev/null; then
        log_warn "Go is not installed"
        need_install=true
    else
        local current_ver
        current_ver=$(go version 2>/dev/null | grep -oP 'go\K[0-9]+\.[0-9]+' | cut -d'.' -f1 || echo "0")
        
        if [[ -z "$current_ver" || "$current_ver" -lt "$required_major" ]]; then
            log_warn "Go is too old (need 1.${required_major}+)"
            need_install=true
        else
            log_info "Go version OK: $(go version)"
            return
        fi
    fi
    
    if [[ "$need_install" == true ]]; then
        log_step "Removing old Go..."
        apt remove --purge golang golang-go -y 2>/dev/null || true
        rm -rf /usr/local/go 2>/dev/null || true
        
        local go_version
        go_version=$(curl -s https://go.dev/dl/?mode=json | grep -oP '"version":\s*"go\K[0-9.]+' | head -1)
        go_version="${go_version:-1.23.4}"
        
        log_step "Downloading Go ${go_version}..."
        curl -fsSL "https://go.dev/dl/go${go_version}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
        
        log_step "Installing Go ${go_version}..."
        tar -C /usr/local -xzf /tmp/go.tar.gz
        rm -f /tmp/go.tar.gz
        
        export PATH=$PATH:/usr/local/go/bin
        if ! grep -q '/usr/local/go/bin' /etc/profile 2>/dev/null; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
        fi
        
        log_info "Go installed: $(go version)"
    fi
}

force_install_nodejs() {
    log_step "Checking Node.js..."
    
    local required_major=20
    local need_install=false
    
    if ! command -v node &>/dev/null; then
        log_warn "Node.js is not installed"
        need_install=true
    else
        local current_ver
        current_ver=$(node -v 2>/dev/null | sed 's/v//' | cut -d'.' -f1 || echo "0")
        
        if [[ -z "$current_ver" || "$current_ver" -lt "$required_major" ]]; then
            log_warn "Node.js is too old (need ${required_major}+)"
            need_install=true
        else
            log_info "Node.js version OK: $(node -v)"
            return
        fi
    fi
    
    if [[ "$need_install" == true ]]; then
        log_step "Removing old Node.js..."
        apt remove --purge nodejs nodejs-* libnode* -y 2>/dev/null || true
        apt autoremove --purge -y 2>/dev/null || true
        rm -rf /usr/lib/node_modules /usr/local/lib/node_modules 2>/dev/null || true
        rm -f /etc/apt/sources.list.d/nodesource.list 2>/dev/null || true
        
        log_step "Installing Node.js 22.x..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
        apt install -y nodejs
        
        log_info "Node.js installed: $(node -v)"
        log_info "npm version: $(npm -v)"
    fi
}

install_system_deps() {
    log_step "Updating package list..."
    apt update -qq
    
    log_step "Installing required packages..."
    apt install -y -qq git ca-certificates build-essential curl
    
    log_info "System dependencies installed"
}

# ─── Backup & Restore ──────────────────────────────────────

backup_current() {
    log_step "Creating backup..."
    mkdir -p "${BACKUP_DIR}"
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    local backup="${BACKUP_DIR}/x-ui.bak.${ts}"
    cp "${BIN}" "${backup}"
    echo "${backup}" > "${BACKUP_DIR}/latest_backup"
    log_info "Backup saved: ${backup}"
}

restore_backup() {
    local backup
    backup="$(cat "${BACKUP_DIR}/latest_backup" 2>/dev/null || echo "")"
    
    if [[ ! -f "${backup}" ]]; then
        log_error "No backup found!"
        echo ""
        log_info "Available backups:"
        ls -lth "${BACKUP_DIR}"/x-ui.bak.* 2>/dev/null | head -5 || log_warn "No backups available"
        return 1
    fi
    
    log_step "Stopping x-ui service..."
    systemctl stop "${SERVICE}" 2>/dev/null || true
    
    log_step "Restoring from backup..."
    cp "${backup}" "${BIN}"
    chmod 755 "${BIN}"
    
    log_step "Starting x-ui service..."
    systemctl start "${SERVICE}" 2>/dev/null || true
    
    log_info "Restored: ${backup}"
    return 0
}

# ─── Build Process ─────────────────────────────────────────

build_theme() {
    print_line
    echo -e "  ${BOLD}Building Anime Theme${NC}"
    print_line
    
    # Prepare workspace
    log_step "Preparing workspace..."
    rm -rf "${WORKDIR}"
    mkdir -p "${WORKDIR}"
    
    # Get theme frontend
    local theme_frontend
    if [[ -d "./${FRONTEND_DIR}" ]]; then
        theme_frontend="$(pwd)/${FRONTEND_DIR}"
        log_info "Using local frontend"
    else
        log_step "Downloading theme from GitHub..."
        git clone --depth 1 "${REPO_THEME}" "${WORKDIR}/theme"
        theme_frontend="${WORKDIR}/theme/${FRONTEND_DIR}"
        log_info "Theme downloaded"
    fi
    
    # Clone main repo
    log_step "Cloning 3x-ui repository..."
    git clone --depth 1 "${REPO_MAIN}" "${WORKDIR}/3x-ui"
    log_info "3x-ui cloned"
    
    # Replace frontend
    log_step "Replacing frontend with anime theme..."
    rm -rf "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
    cp -r "${theme_frontend}" "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
    log_info "Frontend replaced"
    
    # Build frontend
    print_line
    echo -e "  ${BOLD}Building Frontend (npm)${NC}"
    print_line
    
    cd "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
    
    log_step "Installing npm dependencies..."
    npm install
    log_info "Dependencies installed"
    
    log_step "Building frontend bundle..."
    npm run build
    log_info "Frontend built"
    
    if [[ ! -d "${WORKDIR}/3x-ui/web/dist" ]]; then
        log_error "Frontend build failed! web/dist not found"
        return 1
    fi
    
    # Build backend
    print_line
    echo -e "  ${BOLD}Building Backend (Go)${NC}"
    print_line
    
    cd "${WORKDIR}/3x-ui"
    
    log_step "Compiling x-ui with anime theme..."
    go build -ldflags "-w -s" -o x-ui-custom main.go
    
    if [[ ! -f "x-ui-custom" ]]; then
        log_error "Backend build failed!"
        return 1
    fi
    
    local size
    size=$(du -h x-ui-custom | cut -f1)
    log_info "Backend built: x-ui-custom (${size})"
    
    return 0
}

# ─── Installation ──────────────────────────────────────────

install_theme() {
    print_line
    echo -e "  ${BOLD}Installing Theme${NC}"
    print_line
    
    log_step "Stopping x-ui service..."
    systemctl stop "${SERVICE}" 2>/dev/null || true
    
    log_step "Installing new binary..."
    install -m 0755 "${WORKDIR}/3x-ui/x-ui-custom" "${BIN}"
    log_info "Binary installed"
    
    log_step "Starting x-ui service..."
    systemctl start "${SERVICE}" 2>/dev/null || true
    sleep 2
    
    if systemctl is-active --quiet "${SERVICE}"; then
        log_info "Service is running"
    else
        log_warn "Service may not have started. Check: systemctl status x-ui"
    fi
}

# ─── Menus ─────────────────────────────────────────────────

menu_install() {
    clear_screen
    print_banner
    
    print_line
    echo -e "  ${BOLD}System Check${NC}"
    print_line
    check_xui_installed
    press_enter
    
    print_line
    echo -e "  ${BOLD}Installing Dependencies${NC}"
    print_line
    install_system_deps
    force_install_go
    force_install_nodejs
    
    echo ""
    log_info "All dependencies ready"
    log_info "Go:     $(go version 2>/dev/null || echo 'not found')"
    log_info "Node:   $(node -v 2>/dev/null || echo 'not found')"
    log_info "npm:    $(npm -v 2>/dev/null || echo 'not found')"
    press_enter
    
    if ! build_theme; then
        log_error "Build failed!"
        exit 1
    fi
    
    echo ""
    if confirm "Proceed with installation? (backup will be created)"; then
        backup_current
        install_theme
        
        echo ""
        print_line
        echo -e "  ${GREEN}${BOLD}Installation Complete!${NC}"
        echo -e "  ${GREEN}Anime theme is now active on your panel.${NC}"
        echo -e "  ${YELLOW}Clear browser cache to see changes.${NC}"
        print_line
        echo ""
    else
        log_warn "Installation cancelled"
    fi
}

menu_uninstall() {
    clear_screen
    print_banner
    
    print_line
    echo -e "  ${BOLD}Restore Original Panel${NC}"
    print_line
    
    if confirm "This will restore the backup of your original x-ui. Continue?"; then
        if restore_backup; then
            echo ""
            print_line
            echo -e "  ${GREEN}Original Panel Restored!${NC}"
            print_line
        fi
    else
        log_info "Restore cancelled"
    fi
}

menu_status() {
    clear_screen
    print_banner
    
    print_line
    echo -e "  ${BOLD}Status${NC}"
    print_line
    echo ""
    
    echo -e "  ${BOLD}Service:${NC}"
    systemctl status "${SERVICE}" --no-pager 2>/dev/null | head -5 || log_warn "Service not found"
    
    echo ""
    echo -e "  ${BOLD}Backups:${NC}"
    if [[ -d "${BACKUP_DIR}" ]]; then
        ls -lth "${BACKUP_DIR}"/x-ui.bak.* 2>/dev/null | head -5 || log_info "No backups found"
    else
        log_info "No backups directory"
    fi
    
    echo ""
    echo -e "  ${BOLD}Current Binary:${NC}"
    if [[ -f "${BIN}" ]]; then
        log_info "Size: $(du -h "${BIN}" | cut -f1)"
        log_info "Modified: $(stat -c %y "${BIN}" 2>/dev/null || stat -f %Sm "${BIN}" 2>/dev/null)"
    fi
    
    echo ""
    press_enter
}

menu_main() {
    while true; do
        clear_screen
        print_banner
        
        echo ""
        echo -e "  ${BOLD}Select an option:${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC}  Install Anime Theme"
        echo -e "  ${YELLOW}2)${NC}  Uninstall (Restore Original)"
        echo -e "  ${BLUE}3)${NC}  Check Status"
        echo -e "  ${RED}0)${NC}  Exit"
        echo ""
        read -rp "  Enter your choice [0-3]: " choice
        
        case "${choice}" in
            1) menu_install ;;
            2) menu_uninstall ;;
            3) menu_status ;;
            0) 
                echo ""
                log_info "Goodbye!"
                exit 0 
                ;;
            *) log_warn "Invalid option. Try again."; sleep 1 ;;
        esac
    done
}

# ─── Entry Point ───────────────────────────────────────────

main() {
    need_root
    
    if [[ $# -gt 0 ]]; then
        case "${1}" in
            install) menu_install ;;
            uninstall) menu_uninstall ;;
            status) menu_status ;;
            *) 
                echo "Usage: $0 {install|uninstall|status}"
                echo "       $0 (no args for interactive menu)"
                exit 1
                ;;
        esac
    else
        menu_main
    fi
}

main "$@"