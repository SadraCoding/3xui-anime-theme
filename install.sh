#!/bin/bash
# install.sh - One-command installer for 3x-ui Anime Theme
# Author: SadraCoding
# GitHub: https://github.com/SadraCoding/3xui-anime-theme

REPO_OWNER="SadraCoding"
REPO_NAME="3xui-anime-theme"
BRANCH="main"

SCRIPT_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/custom-xui-installer.sh"

echo -e "\033[0;34m═══════════════════════════════════════════════════════════\033[0m"
echo -e "\033[0;32m  3x-ui Anime Theme Installer - by @SadraCoding\033[0m"
echo -e "\033[0;34m═══════════════════════════════════════════════════════════\033[0m"
echo ""

bash <(curl -fsSL "$SCRIPT_URL")