#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  3x-ui Anime Theme Installer v2.0
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
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ─── UI Helpers ───────────────────────────────────────────

clear_screen() { clear; }

print_banner() {
    echo -e "${MAGENTA}"
    echo "    ╔══════════════════════════════════════════════╗"
    echo "    ║           🎨  3x-ui Anime Theme  🎨           ║"
    echo "    ║         SadraCoding/3xui-anime-theme         ║"
    echo "    ╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "  ${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "  ${RED}❌${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}ℹ️${NC}  $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠️${NC}  $1"
}

print_step() {
    echo -e "  ${CYAN}🔄${NC} $1..."
}

print_progress() {
    echo -ne "  ${CYAN}⏳${NC} $1\r"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf "  ${CYAN}[%c]${NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "            \r"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local answer
    
    if [[ "$default" == "y" ]]; then
        read -rp "$(echo -e "  ${YELLOW}❓${NC} ${prompt} [Y/n]: ")" answer
        answer="${answer:-y}"
    else
        read -rp "$(echo -e "  ${YELLOW}❓${NC} ${prompt} [y/N]: ")" answer
        answer="${answer:-n}"
    fi
    
    [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]
}

press_enter() {
    echo ""
    read -rp "$(echo -e "  ${BLUE}🔹 Press Enter to continue...${NC}")"
}

# ─── System Checks ────────────────────────────────────────

need_root() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        print_error "Please run as root (use sudo)."
        exit 1
    fi
}

check_xui_installed() {
    if [[ ! -f "${BIN}" ]]; then
        print_error "3x-ui not found at ${BIN}"
        echo ""
        print_info "Please install 3x-ui first using the official script:"
        echo -e "  ${YELLOW}bash <(curl -fsSL https://raw.githubusercontent.com/MHSanaei/3x-ui/main/install.sh)${NC}"
        exit 1
    fi
    local version
    version=$("${BIN}" version 2>/dev/null | head -1 || echo "unknown")
    print_success "3x-ui found: ${version}"
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="${ID}"
        OS_VERSION="${VERSION_ID}"
    else
        OS="unknown"
    fi
    print_info "OS: ${OS} ${OS_VERSION:-}"
}

# ─── Dependency Installers ─────────────────────────────────

force_install_go() {
    print_step "Checking Go installation"
    
    local required_major=22
    local need_install=false
    
    if ! command -v go &>/dev/null; then
        print_warning "Go is not installed"
        need_install=true
    else
        local current_ver
        current_ver=$(go version 2>/dev/null | grep -oP 'go\K[0-9]+\.[0-9]+' | cut -d'.' -f1 || echo "0")
        
        if [[ -z "$current_ver" || "$current_ver" -lt "$required_major" ]]; then
            print_warning "Go version $(go version 2>/dev/null) is too old (need 1.${required_major}+)"
            need_install=true
        else
            print_success "Go $(go version 2>/dev/null)"
            return
        fi
    fi
    
    if [[ "$need_install" == true ]]; then
        print_step "Removing old Go"
        apt remove --purge golang golang-go golang-1.* -y 2>/dev/null || true
        apt autoremove --purge -y 2>/dev/null || true
        rm -rf /usr/local/go /usr/lib/go /usr/lib/golang 2>/dev/null || true
        
        print_step "Fetching latest Go version"
        local go_version
        go_version=$(curl -s https://go.dev/dl/?mode=json | grep -oP '"version":\s*"go\K[0-9.]+' | head -1)
        go_version="${go_version:-1.23.4}"
        
        print_step "Downloading Go ${go_version}"
        curl -fsSL "https://go.dev/dl/go${go_version}.linux-amd64.tar.gz" -o /tmp/go.tar.gz &
        spinner $!
        
        print_step "Installing Go ${go_version}"
        tar -C /usr/local -xzf /tmp/go.tar.gz
        rm -f /tmp/go.tar.gz
        
        export PATH=$PATH:/usr/local/go/bin
        if ! grep -q '/usr/local/go/bin' /etc/profile 2>/dev/null; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
        fi
        
        print_success "Go $(go version 2>/dev/null) installed"
    fi
}

force_install_nodejs() {
    print_step "Checking Node.js installation"
    
    local required_major=20
    local need_install=false
    
    if ! command -v node &>/dev/null; then
        print_warning "Node.js is not installed"
        need_install=true
    else
        local current_ver
        current_ver=$(node -v 2>/dev/null | sed 's/v//' | cut -d'.' -f1 || echo "0")
        
        if [[ -z "$current_ver" || "$current_ver" -lt "$required_major" ]]; then
            print_warning "Node.js $(node -v 2>/dev/null) is too old (need ${required_major}+)"
            need_install=true
        else
            print_success "Node.js $(node -v 2>/dev/null)"
            return
        fi
    fi
    
    if [[ "$need_install" == true ]]; then
        print_step "Removing old Node.js"
        apt remove --purge nodejs nodejs-* libnode* -y 2>/dev/null || true
        apt autoremove --purge -y 2>/dev/null || true
        rm -rf /usr/lib/node_modules /usr/local/lib/node_modules 2>/dev/null || true
        rm -f /etc/apt/sources.list.d/nodesource.list 2>/dev/null || true
        
        print_step "Installing Node.js 22.x"
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1 &
        spinner $!
        
        apt install -y nodejs > /dev/null 2>&1 &
        spinner $!
        
        print_success "Node.js $(node -v 2>/dev/null) installed"
    fi
}

install_system_deps() {
    print_step "Installing system dependencies"
    apt update -qq 2>/dev/null
    apt install -y -qq git ca-certificates build-essential curl > /dev/null 2>&1 &
    spinner $!
    print_success "System dependencies installed"
}

# ─── Backup & Restore ──────────────────────────────────────

backup_current() {
    print_step "Creating backup"
    mkdir -p "${BACKUP_DIR}"
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    local backup="${BACKUP_DIR}/x-ui.bak.${ts}"
    cp "${BIN}" "${backup}"
    echo "${backup}" > "${BACKUP_DIR}/latest_backup"
    print_success "Backup saved: ${backup}"
}

restore_backup() {
    local backup
    backup="$(cat "${BACKUP_DIR}/latest_backup" 2>/dev/null || echo "")"
    
    if [[ ! -f "${backup}" ]]; then
        print_error "No backup found!"
        echo ""
        print_info "Available backups:"
        ls -lth "${BACKUP_DIR}"/x-ui.bak.* 2>/dev/null | head -5 || print_warning "No backups available"
        return 1
    fi
    
    print_step "Stopping x-ui"
    systemctl stop "${SERVICE}" 2>/dev/null || true
    
    print_step "Restoring from backup"
    cp "${backup}" "${BIN}"
    chmod 755 "${BIN}"
    
    print_step "Starting x-ui"
    systemctl start "${SERVICE}" 2>/dev/null || true
    
    print_success "Restored: ${backup}"
    return 0
}

# ─── Build Process ─────────────────────────────────────────

build_theme() {
    print_section "🔨 Building Anime Theme"
    
    # Prepare workspace
    print_step "Preparing workspace"
    rm -rf "${WORKDIR}"
    mkdir -p "${WORKDIR}"
    print_success "Workspace ready"
    
    # Get theme frontend
    print_step "Locating theme files"
    local theme_frontend
    if [[ -d "./${FRONTEND_DIR}" ]]; then
        theme_frontend="$(pwd)/${FRONTEND_DIR}"
        print_success "Using local frontend: ${theme_frontend}"
    else
        print_step "Downloading theme from GitHub"
        git clone --depth 1 "${REPO_THEME}" "${WORKDIR}/theme" > /dev/null 2>&1 &
        spinner $!
        theme_frontend="${WORKDIR}/theme/${FRONTEND_DIR}"
        print_success "Theme downloaded"
    fi
    
    # Clone main repo
    print_step "Cloning 3x-ui (this may take a minute)"
    git clone --depth 1 "${REPO_MAIN}" "${WORKDIR}/3x-ui" > /dev/null 2>&1 &
    spinner $!
    print_success "3x-ui cloned"
    
    # Replace frontend
    print_step "Replacing frontend with anime theme"
    rm -rf "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
    cp -r "${theme_frontend}" "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
    print_success "Frontend replaced"
    
    # Build frontend
    print_section "📦 Building Frontend (npm)"
    
    cd "${WORKDIR}/3x-ui/${FRONTEND_DIR}"
    
    print_step "Installing npm dependencies"
    npm install --silent > /dev/null 2>&1 &
    spinner $!
    print_success "Dependencies installed"
    
    print_step "Building frontend bundle"
    npm run build > /dev/null 2>&1 &
    spinner $!
    
    if [[ -d "${WORKDIR}/3x-ui/web/dist" ]]; then
        print_success "Frontend built successfully"
    else
        print_error "Frontend build failed!"
        return 1
    fi
    
    # Build backend
    print_section "⚙️  Building Backend (Go)"
    
    cd "${WORKDIR}/3x-ui"
    
    print_step "Compiling x-ui with anime theme"
    go build -ldflags "-w -s" -o x-ui-custom main.go > /dev/null 2>&1 &
    spinner $!
    
    if [[ -f "x-ui-custom" ]]; then
        local size
        size=$(du -h x-ui-custom | cut -f1)
        print_success "Backend built successfully (${size})"
        return 0
    else
        print_error "Backend build failed!"
        return 1
    fi
}

# ─── Installation ──────────────────────────────────────────

install_theme() {
    print_section "📥 Installing Theme"
    
    print_step "Stopping x-ui service"
    systemctl stop "${SERVICE}" 2>/dev/null || true
    print_success "Service stopped"
    
    print_step "Installing new binary"
    install -m 0755 "${WORKDIR}/3x-ui/x-ui-custom" "${BIN}"
    print_success "Binary installed"
    
    print_step "Starting x-ui service"
    systemctl start "${SERVICE}" 2>/dev/null || true
    sleep 2
    
    if systemctl is-active --quiet "${SERVICE}"; then
        print_success "Service is running"
    else
        print_warning "Service may not have started. Check: systemctl status x-ui"
    fi
}

# ─── Main Menus ────────────────────────────────────────────

menu_install() {
    clear_screen
    print_banner
    
    print_section "📋 System Check"
    check_xui_installed
    detect_os
    press_enter
    
    print_section "🔧 Installing Dependencies"
    install_system_deps
    force_install_go
    force_install_nodejs
    
    echo ""
    print_success "All dependencies ready!"
    print_info "Go:     $(go version 2>/dev/null || echo 'not found')"
    print_info "Node:   $(node -v 2>/dev/null || echo 'not found')"
    print_info "npm:    $(npm -v 2>/dev/null || echo 'not found')"
    press_enter
    
    if ! build_theme; then
        print_error "Build failed! Please check the logs."
        exit 1
    fi
    
    echo ""
    if confirm "Proceed with installation? (backup will be created)"; then
        backup_current
        install_theme
        
        echo ""
        echo -e "${GREEN}  ╔══════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}  ║     🎉 Anime Theme Installed Successfully!  ║${NC}"
        echo -e "${GREEN}  ║        Clear browser cache to see it        ║${NC}"
        echo -e "${GREEN}  ╚══════════════════════════════════════════════╝${NC}"
        echo ""
    else
        print_warning "Installation cancelled."
    fi
}

menu_uninstall() {
    clear_screen
    print_banner
    print_section "🔙 Restore Original Panel"
    
    if confirm "This will restore the backup of your original x-ui. Continue?"; then
        if restore_backup; then
            echo ""
            echo -e "${GREEN}  ╔══════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}  ║      ✅ Original Panel Restored!            ║${NC}"
            echo -e "${GREEN}  ╚══════════════════════════════════════════════╝${NC}"
        fi
    else
        print_info "Restore cancelled."
    fi
}

menu_status() {
    clear_screen
    print_banner
    print_section "📊 Status"
    
    echo -e "  ${BOLD}Service:${NC}"
    systemctl status "${SERVICE}" --no-pager 2>/dev/null | head -5 || print_warning "Service not found"
    
    echo ""
    echo -e "  ${BOLD}Backups:${NC}"
    if [[ -d "${BACKUP_DIR}" ]]; then
        ls -lth "${BACKUP_DIR}"/x-ui.bak.* 2>/dev/null | head -5 || print_info "No backups found"
    else
        print_info "No backups yet"
    fi
    
    echo ""
    echo -e "  ${BOLD}Current Binary:${NC}"
    if [[ -f "${BIN}" ]]; then
        print_info "Size: $(du -h "${BIN}" | cut -f1)"
        print_info "Modified: $(stat -c %y "${BIN}" 2>/dev/null || stat -f %Sm "${BIN}" 2>/dev/null)"
    fi
    
    echo ""
    press_enter
}

menu_main() {
    while true; do
        clear_screen
        print_banner
        
        echo ""
        echo -e "  ${BOLD}Please select an option:${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC}  🎨  Install Anime Theme"
        echo -e "  ${YELLOW}2)${NC}  🔙  Uninstall (Restore Original)"
        echo -e "  ${BLUE}3)${NC}  📊  Check Status"
        echo -e "  ${RED}0)${NC}  🚪  Exit"
        echo ""
        read -rp "$(echo -e "  ${CYAN}Enter your choice [0-3]:${NC} ")" choice
        
        case "${choice}" in
            1) menu_install ;;
            2) menu_uninstall ;;
            3) menu_status ;;
            0) 
                echo ""
                print_info "Goodbye! 👋"
                exit 0 
                ;;
            *) print_warning "Invalid option. Try again."; sleep 1 ;;
        esac
    done
}

# ─── Entry Point ───────────────────────────────────────────

main() {
    need_root
    
    # If arguments passed, run directly
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
        # Interactive menu
        menu_main
    fi
}

main "$@"