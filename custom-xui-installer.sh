#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Custom 3x-ui Installer - Anime Theme by @SadraCoding
#  GitHub: https://github.com/SadraCoding/3xui-anime-theme
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# ===== CONFIGURATION =====
REPO_OWNER="SadraCoding"
REPO_NAME="3xui-anime-theme"
BRANCH="main"  # Changed from master to main

# Your custom frontend repo (same as installer repo)
CUSTOM_FRONTEND_REPO="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
ORIGINAL_XUI_REPO="https://github.com/MHSanaei/3x-ui.git"

XUI_INSTALL_DIR="/usr/local/x-ui"
WORK_DIR="/tmp/3xui-anime-build"
# =========================

error_exit() { echo -e "${RED}ERROR: $1${PLAIN}" && exit 1; }
print_info() { echo -e "${GREEN}[INFO]${PLAIN} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${PLAIN} $1"; }

print_header() { 
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${PLAIN}"
    echo -e "${GREEN}  3x-ui Anime Theme Installer - by @SadraCoding${PLAIN}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${PLAIN}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "Please run as root (use sudo)"
    fi
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    apt-get update -qq 2>/dev/null || true
    
    # Install basic dependencies
    apt-get install -y -qq git curl tar gcc make 2>/dev/null || true
    
    # Install Go if not present
    if ! command -v go &> /dev/null; then
        print_info "Installing Go..."
        wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
        tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        rm go1.21.5.linux-amd64.tar.gz
    fi
    
    # Install Node.js 20 if not present or too old
    if ! command -v node &> /dev/null; then
        print_info "Installing Node.js 20 LTS..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    fi
    
    print_info "All dependencies satisfied"
}

clone_repositories() {
    print_info "Cloning repositories..."
    
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    
    # Clone original 3x-ui (using main branch)
    print_info "Cloning original 3x-ui..."
    git clone --depth 1 --branch main "$ORIGINAL_XUI_REPO" "$WORK_DIR/original"
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to clone original 3x-ui repository"
    fi
    
    # Clone your custom frontend (your repo)
    print_info "Cloning your anime theme from: $CUSTOM_FRONTEND_REPO"
    git clone --depth 1 --branch "$BRANCH" "$CUSTOM_FRONTEND_REPO" "$WORK_DIR/custom"
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to clone your custom frontend repository"
    fi
    
    # Check if frontend folder exists in your repo
    if [[ ! -d "$WORK_DIR/custom/frontend" ]]; then
        print_warning "frontend folder not found in your repository root"
        print_warning "Looking for frontend in subdirectories..."
        
        # Try to find frontend folder anywhere in your repo
        FRONTEND_DIR=$(find "$WORK_DIR/custom" -type d -name "frontend" | head -1)
        if [[ -n "$FRONTEND_DIR" ]]; then
            print_info "Found frontend at: $FRONTEND_DIR"
            cp -r "$FRONTEND_DIR" "$WORK_DIR/original/frontend"
        else
            error_exit "Could not find frontend folder in your repository"
        fi
    else
        # Replace frontend folder
        rm -rf "$WORK_DIR/original/frontend"
        cp -r "$WORK_DIR/custom/frontend" "$WORK_DIR/original/frontend"
    fi
    
    print_info "Repositories cloned and frontend replaced"
}

build_frontend() {
    print_info "Building custom anime frontend..."
    
    cd "$WORK_DIR/original/frontend"
    
    if [[ ! -f "package.json" ]]; then
        error_exit "package.json not found in frontend folder"
    fi
    
    print_info "Installing npm dependencies..."
    npm install --no-fund --no-audit 2>/dev/null || npm install
    
    print_info "Building Vue 3 frontend..."
    npm run build
    
    if [[ $? -ne 0 ]]; then
        error_exit "Frontend build failed"
    fi
    
    if [[ ! -d "dist" ]]; then
        error_exit "Build output 'dist' directory not found"
    fi
    
    # Copy built files to where Go expects them
    rm -rf "$WORK_DIR/original/web/dist"
    cp -r dist "$WORK_DIR/original/web/dist"
    
    print_info "Frontend built successfully"
}

build_go_binary() {
    print_info "Building Go binary with embedded anime theme..."
    
    cd "$WORK_DIR/original"
    
    # Download Go modules
    go mod download 2>/dev/null || true
    
    # Build the binary
    CGO_ENABLED=1 go build -ldflags "-w -s" -o x-ui-custom main.go
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to build Go binary"
    fi
    
    print_info "Go binary built successfully"
}

install_xui() {
    print_info "Installing 3x-ui with anime theme..."
    
    # Stop existing service if running
    systemctl stop x-ui 2>/dev/null || true
    
    # Create directories
    mkdir -p "$XUI_INSTALL_DIR"
    mkdir -p /var/log/x-ui
    
    # Copy binary
    cp -f "$WORK_DIR/original/x-ui-custom" "$XUI_INSTALL_DIR/x-ui"
    chmod +x "$XUI_INSTALL_DIR/x-ui"
    
    # Copy management script
    cp -f "$WORK_DIR/original/x-ui.sh" /usr/bin/x-ui
    chmod +x /usr/bin/x-ui
    
    # Install systemd service
    if [[ -f "$WORK_DIR/original/x-ui.service" ]]; then
        cp -f "$WORK_DIR/original/x-ui.service" /etc/systemd/system/x-ui.service
    else
        cat > /etc/systemd/system/x-ui.service <<'EOF'
[Unit]
Description=3x-ui Service
After=network.target nss-lookup.target

[Service]
Type=simple
ExecStart=/usr/local/x-ui/x-ui
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
    
    print_info "3x-ui installed and started successfully"
}

configure_firewall() {
    if command -v ufw &> /dev/null; then
        ufw allow 2053/tcp comment '3x-ui panel' 2>/dev/null || true
        ufw allow 2096/tcp comment '3x-ui subscription' 2>/dev/null || true
    fi
}

show_completion() {
    local server_ip=$(curl -s -4 icanhazip.com 2>/dev/null || echo "localhost")
    
    print_header
    echo ""
    echo -e "${GREEN}✅ Installation Complete! Your Anime-themed 3x-ui is ready!${PLAIN}"
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${YELLOW}║                    PANEL ACCESS INFO                     ║${PLAIN}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${GREEN}🌐 Access URL:${PLAIN} http://$server_ip:2053/"
    echo -e "${GREEN}👤 Username:${PLAIN}   admin"
    echo -e "${GREEN}🔑 Password:${PLAIN}   admin"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: Change your password immediately after first login!${PLAIN}"
    echo ""
    echo -e "${BLUE}📌 Useful commands:${PLAIN}"
    echo -e "  ${GREEN}x-ui${PLAIN}          - Show management menu"
    echo -e "  ${GREEN}x-ui status${PLAIN}    - Check panel status"
    echo -e "  ${GREEN}x-ui restart${PLAIN}  - Restart panel"
    echo -e "  ${GREEN}x-ui stop${PLAIN}     - Stop panel"
    echo ""
    echo -e "${GREEN}🎨 Enjoy your beautiful anime-themed 3x-ui panel!${PLAIN}"
    echo ""
}

cleanup() {
    read -rp "Delete temporary build files? [y/N]: " choice
    if [[ "$choice" == "y" ]] || [[ "$choice" == "Y" ]]; then
        rm -rf "$WORK_DIR"
        print_info "Cleanup completed"
    fi
}

main() {
    print_header
    echo ""
    check_root
    check_dependencies
    clone_repositories
    build_frontend
    build_go_binary
    install_xui
    configure_firewall
    show_completion
    cleanup
}

main "$@"