#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Custom 3x-ui Installer - Replace frontend with custom version
#  Author: Your Name
#  Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/install.sh | bash
# ============================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# Configuration - CHANGE THESE TO YOUR REPO
CUSTOM_FRONTEND_REPO="https://github.com/SadraCoding/3xui-anime-theme.git"
CUSTOM_FRONTEND_BRANCH="main"  # or "master"
ORIGINAL_XUI_REPO="https://github.com/MHSanaei/3x-ui.git"

# Installation paths
XUI_INSTALL_DIR="/usr/local/x-ui"
WORK_DIR="/tmp/3x-ui-custom-build"

# ============================================================
# Helper Functions
# ============================================================

error_exit() {
    echo -e "${RED}ERROR: $1${PLAIN}"
    exit 1
}

print_info() {
    echo -e "${GREEN}[INFO]${PLAIN} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${PLAIN} $1"
}

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${PLAIN}"
    echo -e "${GREEN}$1${PLAIN}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${PLAIN}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "Please run as root (use sudo)"
    fi
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    local deps=("git" "curl" "tar" "golang-go" "npm" "nodejs" "gcc" "make")
    local missing=()
    
    # Update package list
    apt-get update -qq
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_info "Installing missing dependencies: ${missing[*]}"
        apt-get install -y -qq "${missing[@]}"
    fi
    
    # Ensure Node.js is recent enough (v18+)
    local node_version=$(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ -z "$node_version" ]] || [[ "$node_version" -lt 18 ]]; then
        print_info "Installing Node.js 20 LTS..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    fi
    
    print_info "All dependencies satisfied"
}

clone_original_xui() {
    print_info "Cloning original 3x-ui from $ORIGINAL_XUI_REPO"
    
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    
    git clone --depth 1 --branch master "$ORIGINAL_XUI_REPO" "$WORK_DIR"
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to clone original 3x-ui repository"
    fi
    
    print_info "Successfully cloned original 3x-ui"
}

clone_custom_frontend() {
    print_info "Cloning custom frontend from $CUSTOM_FRONTEND_REPO (branch: $CUSTOM_FRONTEND_BRANCH)"
    
    rm -rf "$WORK_DIR/frontend"
    
    git clone --depth 1 --branch "$CUSTOM_FRONTEND_BRANCH" "$CUSTOM_FRONTEND_REPO" "$WORK_DIR/frontend"
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to clone custom frontend repository"
    fi
    
    print_info "Successfully cloned custom frontend"
}

build_frontend() {
    print_info "Building custom frontend..."
    
    cd "$WORK_DIR/frontend"
    
    # Check if package.json exists
    if [[ ! -f "package.json" ]]; then
        error_exit "package.json not found in custom frontend"
    fi
    
    # Install dependencies
    print_info "Installing npm dependencies..."
    npm install --no-fund --no-audit
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to install npm dependencies"
    fi
    
    # Build the frontend
    print_info "Building Vue 3 frontend..."
    npm run build
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to build frontend"
    fi
    
    # Verify build output
    if [[ ! -d "dist" ]]; then
        error_exit "Build directory 'dist' not found"
    fi
    
    # Copy built files to web/dist (where Go expects them)
    rm -rf "$WORK_DIR/web/dist"
    cp -r dist "$WORK_DIR/web/dist"
    
    print_info "Frontend built successfully"
}

backup_existing_installation() {
    if [[ -d "$XUI_INSTALL_DIR" ]]; then
        local backup_dir="/tmp/xui-backup-$(date +%Y%m%d-%H%M%S)"
        print_info "Backing up existing installation to $backup_dir"
        cp -r "$XUI_INSTALL_DIR" "$backup_dir"
    fi
}

build_go_binary() {
    print_info "Building Go binary with embedded custom frontend..."
    
    cd "$WORK_DIR"
    
    # Download Go modules
    go mod download
    
    # Build the binary
    CGO_ENABLED=1 go build -ldflags "-w -s" -o x-ui-custom main.go
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to build Go binary"
    fi
    
    print_info "Go binary built successfully"
}

install_xui() {
    print_info "Installing 3x-ui with custom frontend..."
    
    # Stop existing service if running
    if systemctl is-active --quiet x-ui; then
        print_info "Stopping existing x-ui service..."
        systemctl stop x-ui
    fi
    
    # Create installation directory
    mkdir -p "$XUI_INSTALL_DIR"
    
    # Copy binary
    cp -f "$WORK_DIR/x-ui-custom" "$XUI_INSTALL_DIR/x-ui"
    chmod +x "$XUI_INSTALL_DIR/x-ui"
    
    # Copy x-ui.sh script
    cp -f "$WORK_DIR/x-ui.sh" /usr/bin/x-ui
    chmod +x /usr/bin/x-ui
    
    # Create log directory
    mkdir -p /var/log/x-ui
    
    # Install systemd service
    if [[ -f "$WORK_DIR/x-ui.service" ]]; then
        cp -f "$WORK_DIR/x-ui.service" /etc/systemd/system/x-ui.service
    elif [[ -f "$WORK_DIR/x-ui.service.debian" ]]; then
        cp -f "$WORK_DIR/x-ui.service.debian" /etc/systemd/system/x-ui.service
    else
        # Create default service file
        cat > /etc/systemd/system/x-ui.service <<EOF
[Unit]
Description=3x-ui Service
After=network.target nss-lookup.target

[Service]
Type=simple
ExecStart=$XUI_INSTALL_DIR/x-ui
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    # Reload systemd and start service
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    
    print_info "Xray service started successfully"
}

configure_firewall() {
    print_info "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 2053/tcp comment '3x-ui panel'
        ufw allow 2096/tcp comment '3x-ui subscription'
        ufw --force enable
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=2053/tcp
        firewall-cmd --permanent --add-port=2096/tcp
        firewall-cmd --reload
    fi
}

show_completion_message() {
    print_header "Installation Complete!"
    
    # Get server IP
    local server_ip=$(curl -s -4 icanhazip.com 2>/dev/null || echo "localhost")
    
    echo -e "${GREEN}✅ 3x-ui with your custom frontend has been installed!${PLAIN}"
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${YELLOW}║                    PANEL ACCESS INFO                     ║${PLAIN}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${GREEN}Access URL:${PLAIN} http://$server_ip:2053/"
    echo -e "${GREEN}Default username:${PLAIN} admin"
    echo -e "${GREEN}Default password:${PLAIN} admin"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: Change your password immediately after first login!${PLAIN}"
    echo ""
    echo -e "${BLUE}Commands:${PLAIN}"
    echo -e "  ${GREEN}x-ui${PLAIN}          - Show menu"
    echo -e "  ${GREEN}x-ui start${PLAIN}    - Start panel"
    echo -e "  ${GREEN}x-ui stop${PLAIN}     - Stop panel"
    echo -e "  ${GREEN}x-ui restart${PLAIN}  - Restart panel"
    echo -e "  ${GREEN}x-ui status${PLAIN}   - Check status"
    echo ""
    echo -e "${YELLOW}Your custom frontend has been successfully integrated!${PLAIN}"
}

cleanup() {
    print_info "Cleaning up temporary files..."
    rm -rf "$WORK_DIR"
}

# ============================================================
# Main Installation Flow
# ============================================================

main() {
    print_header "Custom 3x-ui Installer"
    echo -e "${GREEN}Custom Frontend Repository:${PLAIN} $CUSTOM_FRONTEND_REPO"
    echo ""
    
    # Run installation steps
    check_root
    check_dependencies
    backup_existing_installation
    clone_original_xui
    clone_custom_frontend
    build_frontend
    build_go_binary
    install_xui
    configure_firewall
    show_completion_message
    
    # Optional: ask about cleanup
    echo ""
    read -rp "Delete temporary build files? [y/N]: " cleanup_choice
    if [[ "$cleanup_choice" == "y" ]] || [[ "$cleanup_choice" == "Y" ]]; then
        cleanup
    fi
}

# Run main function
main "$@"