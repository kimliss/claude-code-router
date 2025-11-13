#!/bin/bash

set -e

INSTALL_DIR="$HOME/.claude-code-router-bin"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.claude-code-router"
TEMP_DIR=$(mktemp -d)

# Cleanup function
cleanup() {
  if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

function log_error() {
  echo "❌ Error: $1" >&2
}

function log_info() {
  echo "ℹ️  $1"
}

function log_success() {
  echo "✅ $1"
}

function show_help() {
  cat <<'EOF'
Usage: setup.sh [command] [options]

Commands:
  install [version]  Install claude-code-router (default: latest)
  uninstall          Uninstall claude-code-router
  help               Show this help message

Examples:
  setup.sh install
  setup.sh install v1.0.65
  setup.sh uninstall
EOF
}

function check_dependencies() {
  local missing_deps=()
  
  for cmd in curl tar sudo; do
    if ! command -v "$cmd" &> /dev/null; then
      missing_deps+=("$cmd")
    fi
  done
  
  if [ ${#missing_deps[@]} -ne 0 ]; then
    log_error "Missing required dependencies: ${missing_deps[*]}"
    exit 1
  fi
}

function install() {
  VERSION=${1:-latest}
  
  log_info "Installing claude-code-router ($VERSION)..."
  
  # Check dependencies
  check_dependencies
  
  # Determine download URL
  if [ "$VERSION" = "latest" ]; then
    DOWNLOAD_URL="https://github.com/musistudio/claude-code-router/releases/latest/download/claude-code-router-macos.tar.gz"
  else
    DOWNLOAD_URL="https://github.com/musistudio/claude-code-router/releases/download/$VERSION/claude-code-router-macos.tar.gz"
  fi
  
  # Create install directory
  mkdir -p "$INSTALL_DIR"
  
  # Download to temp directory
  log_info "Downloading from $DOWNLOAD_URL..."
  if ! curl -fL "$DOWNLOAD_URL" -o "$TEMP_DIR/claude-code-router.tar.gz"; then
    log_error "Failed to download claude-code-router"
    log_info "Please check:"
    log_info "  - Your internet connection"
    log_info "  - The version '$VERSION' exists"
    log_info "  - URL: $DOWNLOAD_URL"
    exit 1
  fi
  
  # Verify download
  if [ ! -s "$TEMP_DIR/claude-code-router.tar.gz" ]; then
    log_error "Downloaded file is empty"
    exit 1
  fi
  
  # Extract
  log_info "Extracting files..."
  if ! tar -xzf "$TEMP_DIR/claude-code-router.tar.gz" -C "$INSTALL_DIR"; then
    log_error "Failed to extract archive"
    exit 1
  fi
  
  # Verify extraction
  if [ ! -f "$INSTALL_DIR/claude-code-router/dist/cli.js" ]; then
    log_error "Expected file not found after extraction"
    log_info "Archive structure may have changed"
    exit 1
  fi
  
  # Make executable
  chmod +x "$INSTALL_DIR/claude-code-router/dist/cli.js"
  
  # Create symlink (ask for sudo only when needed)
  log_info "Creating command line tool..."
  if ! sudo -v; then
    log_error "sudo access required to create symlink in $BIN_DIR"
    exit 1
  fi
  
  # Remove old symlink if exists
  if [ -L "$BIN_DIR/ccr" ] || [ -f "$BIN_DIR/ccr" ]; then
    sudo rm -f "$BIN_DIR/ccr"
  fi
  
  # Create new symlink
  if ! sudo ln -sf "$INSTALL_DIR/claude-code-router/dist/cli.js" "$BIN_DIR/ccr"; then
    log_error "Failed to create symlink"
    exit 1
  fi
  
  # Verify installation
  if ! command -v ccr &> /dev/null; then
    log_error "Installation completed but 'ccr' command not found"
    log_info "You may need to add $BIN_DIR to your PATH"
    exit 1
  fi
  
  log_success "Installation complete!"
  echo ""
  log_info "Run 'ccr --help' to get started"
  
  # Show version if possible
  if ccr --version &> /dev/null; then
    echo ""
    ccr --version
  fi
}

function uninstall() {
  log_info "Uninstalling claude-code-router..."
  
  # Stop the service if running
  if [ -f "$CONFIG_DIR/.claude-code-router.pid" ]; then
    log_info "Stopping service..."
    if command -v ccr &> /dev/null; then
      ccr stop 2>/dev/null || true
    fi
  fi
  
  # Remove symlink
  if [ -L "$BIN_DIR/ccr" ] || [ -f "$BIN_DIR/ccr" ]; then
    log_info "Removing command line tool..."
    if ! sudo rm -f "$BIN_DIR/ccr"; then
      log_error "Failed to remove $BIN_DIR/ccr (need sudo)"
      log_info "You may need to manually remove it: sudo rm $BIN_DIR/ccr"
    fi
  fi
  
  # Remove installation directory
  if [ -d "$INSTALL_DIR" ]; then
    log_info "Removing installation files..."
    rm -rf "$INSTALL_DIR"
  fi
  
  # Ask about configuration
  echo ""
  read -p "Do you want to remove configuration files at $CONFIG_DIR? (y/N) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$CONFIG_DIR" ]; then
      log_info "Removing configuration files..."
      rm -rf "$CONFIG_DIR"
    fi
  else
    log_info "Configuration files kept at $CONFIG_DIR"
  fi
  
  log_success "Uninstallation complete!"
}

# Main logic
case "${1:-help}" in
  install)
    install "$2"
    ;;
  uninstall)
    uninstall
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    log_error "Unknown command: $1"
    echo ""
    show_help
    exit 1
    ;;
esac
