#!/usr/bin/env bash

#===============================================================================
# Claude Code Router - Installation Script
# Description: Install, uninstall, and manage claude-code-router
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
readonly SCRIPT_VERSION="1.0.0"
readonly INSTALL_DIR="$HOME/.claude-code-router-bin"
readonly BIN_DIR="/usr/local/bin"
readonly CONFIG_DIR="$HOME/.claude-code-router"
readonly GITHUB_REPO="kimliss/claude-code-router"
readonly BINARY_NAME="ccr"

#-------------------------------------------------------------------------------
# Colors and Logging
#-------------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ${NC}  $*"
}

log_success() {
    echo -e "${GREEN}✓${NC}  $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC}  $*"
}

log_error() {
    echo -e "${RED}✗${NC}  $*" >&2
}

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in curl tar; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install them first"
        return 1
    fi
    
    return 0
}

# Check if running as root
is_root() {
    [ "$(id -u)" -eq 0 ]
}

# Request sudo access
ensure_sudo() {
    if is_root; then
        return 0
    fi
    
    if ! sudo -v; then
        log_error "This operation requires sudo privileges"
        return 1
    fi
    
    # Keep sudo alive
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done 2>/dev/null &
    
    return 0
}

# Create directory safely
create_directory() {
    local dir="$1"
    
    if [ -d "$dir" ]; then
        return 0
    fi
    
    if ! mkdir -p "$dir"; then
        log_error "Failed to create directory: $dir"
        return 1
    fi
    
    return 0
}

# Download file with retry
download_file() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if curl -fsSL --connect-timeout 10 --max-time 300 "$url" -o "$output"; then
            return 0
        fi
        
        retry=$((retry + 1))
        if [ $retry -lt $max_retries ]; then
            log_warn "Download failed, retrying ($retry/$max_retries)..."
            sleep 2
        fi
    done
    
    log_error "Failed to download after $max_retries attempts"
    return 1
}

#-------------------------------------------------------------------------------
# Installation Functions
#-------------------------------------------------------------------------------

# Get download URL for version
get_download_url() {
    local version="$1"
    local filename="claude-code-router-macos.tar.gz"
    
    if [ "$version" = "latest" ]; then
        echo "https://github.com/${GITHUB_REPO}/releases/latest/download/${filename}"
    else
        echo "https://github.com/${GITHUB_REPO}/releases/download/${version}/${filename}"
    fi
}

# Install claude-code-router
install_ccr() {
    local version="${1:-latest}"
    local temp_dir
    
    echo ""
    log_info "Installing claude-code-router (version: $version)"
    echo ""
    
    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi
    
    # Create temporary directory
    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT
    
    # Get download URL
    local download_url
    download_url=$(get_download_url "$version")
    
    # Download archive
    log_info "Downloading from GitHub..."
    if ! download_file "$download_url" "$temp_dir/archive.tar.gz"; then
        log_error "Download failed"
        log_info "URL: $download_url"
        log_info "Please check:"
        log_info "  • Your internet connection"
        log_info "  • The version exists: https://github.com/${GITHUB_REPO}/releases"
        return 1
    fi
    
    # Verify archive
    if [ ! -s "$temp_dir/archive.tar.gz" ]; then
        log_error "Downloaded file is empty"
        return 1
    fi
    
    log_success "Download complete"
    
    # Create installation directory
    log_info "Preparing installation directory..."
    if ! create_directory "$INSTALL_DIR"; then
        return 1
    fi
    
    # Extract archive
    log_info "Extracting files..."
    if ! tar -xzf "$temp_dir/archive.tar.gz" -C "$INSTALL_DIR"; then
        log_error "Failed to extract archive"
        return 1
    fi
    
    # Verify extracted files
    local cli_path="$INSTALL_DIR/claude-code-router/dist/cli.js"
    if [ ! -f "$cli_path" ]; then
        log_error "Expected file not found: $cli_path"
        log_info "The archive structure may have changed"
        return 1
    fi
    
    # Make executable
    chmod +x "$cli_path"
    log_success "Files extracted"
    
    # Install binary
    log_info "Installing command line tool..."
    if ! install_binary; then
        return 1
    fi
    
    # Verify installation
    if ! command_exists "$BINARY_NAME"; then
        log_error "Installation completed but '$BINARY_NAME' command not found"
        log_warn "You may need to add $BIN_DIR to your PATH"
        return 1
    fi
    
    echo ""
    log_success "Installation complete!"
    echo ""
    log_info "Run '$BINARY_NAME --help' to get started"
    
    # Show version
    if $BINARY_NAME --version >/dev/null 2>&1; then
        echo ""
        $BINARY_NAME --version
    fi
    
    return 0
}

# Install binary to system path
install_binary() {
    local source="$INSTALL_DIR/claude-code-router/dist/cli.js"
    local target="$BIN_DIR/$BINARY_NAME"
    
    # Check if we need sudo
    if [ ! -w "$BIN_DIR" ]; then
        if ! ensure_sudo; then
            return 1
        fi
    fi
    
    # Remove old installation
    if [ -e "$target" ]; then
        if [ -w "$BIN_DIR" ]; then
            rm -f "$target"
        else
            sudo rm -f "$target"
        fi
    fi
    
    # Create symlink
    if [ -w "$BIN_DIR" ]; then
        ln -sf "$source" "$target"
    else
        sudo ln -sf "$source" "$target"
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Failed to create symlink"
        return 1
    fi
    
    log_success "Command line tool installed"
    return 0
}

#-------------------------------------------------------------------------------
# Uninstallation Functions
#-------------------------------------------------------------------------------

# Stop running service
stop_service() {
    local pid_file="$CONFIG_DIR/.claude-code-router.pid"
    
    if [ ! -f "$pid_file" ]; then
        return 0
    fi
    
    log_info "Stopping running service..."
    
    if command_exists "$BINARY_NAME"; then
        $BINARY_NAME stop 2>/dev/null || true
    fi
    
    log_success "Service stopped"
    return 0
}

# Remove binary
remove_binary() {
    local target="$BIN_DIR/$BINARY_NAME"
    
    if [ ! -e "$target" ]; then
        return 0
    fi
    
    log_info "Removing command line tool..."
    
    if [ -w "$BIN_DIR" ]; then
        rm -f "$target"
    else
        if ! ensure_sudo; then
            log_warn "Could not remove $target (permission denied)"
            log_info "Please remove manually: sudo rm $target"
            return 1
        fi
        sudo rm -f "$target"
    fi
    
    log_success "Command line tool removed"
    return 0
}

# Remove installation files
remove_installation() {
    if [ ! -d "$INSTALL_DIR" ]; then
        return 0
    fi
    
    log_info "Removing installation files..."
    rm -rf "$INSTALL_DIR"
    log_success "Installation files removed"
    return 0
}

# Remove configuration files
remove_configuration() {
    if [ ! -d "$CONFIG_DIR" ]; then
        return 0
    fi
    
    echo ""
    read -r -p "Remove configuration files at $CONFIG_DIR? [y/N] " response
    
    case "$response" in
        [yY][eE][sS]|[yY])
            log_info "Removing configuration files..."
            rm -rf "$CONFIG_DIR"
            log_success "Configuration files removed"
            ;;
        *)
            log_info "Configuration files kept at: $CONFIG_DIR"
            ;;
    esac
    
    return 0
}

# Uninstall claude-code-router
uninstall_ccr() {
    echo ""
    log_info "Uninstalling claude-code-router"
    echo ""
    
    stop_service
    remove_binary
    remove_installation
    remove_configuration
    
    echo ""
    log_success "Uninstallation complete!"
    
    return 0
}

#-------------------------------------------------------------------------------
# Information Functions
#-------------------------------------------------------------------------------

# Show version
show_version() {
    echo "claude-code-router setup script v${SCRIPT_VERSION}"
}

# Show help
show_help() {
    cat <<'HELP'
Claude Code Router - Installation Script

USAGE:
    setup.sh [COMMAND] [OPTIONS]

COMMANDS:
    install [VERSION]    Install claude-code-router
                         VERSION: version tag or 'latest' (default)
    
    uninstall            Uninstall claude-code-router
    
    version              Show script version
    
    help                 Show this help message

EXAMPLES:
    # Install latest version
    ./setup.sh install
    
    # Install specific version
    ./setup.sh install v1.0.65
    
    # Uninstall
    ./setup.sh uninstall

DIRECTORIES:
    Installation:  ~/.claude-code-router-bin
    Configuration: ~/.claude-code-router
    Binary:        /usr/local/bin/ccr

HELP
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------

main() {
    local command="${1:-help}"
    
    case "$command" in
        install)
            install_ccr "${2:-latest}"
            ;;
        
        uninstall)
            uninstall_ccr
            ;;
        
        version|--version|-v)
            show_version
            ;;
        
        help|--help|-h)
            show_help
            ;;
        
        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
