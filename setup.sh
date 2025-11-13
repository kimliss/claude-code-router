#!/bin/bash  
  
set -e  
  
INSTALL_DIR="$HOME/.claude-code-router-bin"  
BIN_DIR="/usr/local/bin"  
CONFIG_DIR="$HOME/.claude-code-router"  
  
function show_help() {  
  cat << EOF  
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
  
function install() {  
  VERSION=${1:-latest}  
    
  echo "Installing claude-code-router..."  
    
  # Download release  
  if [ "$VERSION" = "latest" ]; then  
    DOWNLOAD_URL="https://github.com/musistudio/claude-code-router/releases/latest/download/claude-code-router-macos.tar.gz"  
  else  
    DOWNLOAD_URL="https://github.com/musistudio/claude-code-router/releases/download/$VERSION/claude-code-router-macos.tar.gz"  
  fi  
    
  # Create install directory  
  mkdir -p "$INSTALL_DIR"  
  cd "$INSTALL_DIR"  
    
  # Download and extract  
  curl -L "$DOWNLOAD_URL" -o claude-code-router.tar.gz  
  tar -xzf claude-code-router.tar.gz  
  rm claude-code-router.tar.gz  
    
  # Create symlink  
  sudo ln -sf "$INSTALL_DIR/claude-code-router/dist/cli.js" "$BIN_DIR/ccr"  
  sudo chmod +x "$BIN_DIR/ccr"  
    
  echo "✅ Installation complete!"  
  echo "Run 'ccr --help' to get started"  
}  
  
function uninstall() {  
  echo "Uninstalling claude-code-router..."  
    
  # Stop the service if running  
  if [ -f "$CONFIG_DIR/.claude-code-router.pid" ]; then  
    echo "Stopping service..."  
    ccr stop 2>/dev/null || true  
  fi  
    
  # Remove symlink  
  if [ -L "$BIN_DIR/ccr" ]; then  
    echo "Removing command line tool..."  
    sudo rm -f "$BIN_DIR/ccr"  
  fi  
    
  # Remove installation directory  
  if [ -d "$INSTALL_DIR" ]; then  
    echo "Removing installation files..."  
    rm -rf "$INSTALL_DIR"  
  fi  
    
  # Ask user if they want to remove configuration  
  read -p "Do you want to remove configuration files at $CONFIG_DIR? (y/N) " -n 1 -r  
  echo  
  if [[ $REPLY =~ ^[Yy]$ ]]; then  
    if [ -d "$CONFIG_DIR" ]; then  
      echo "Removing configuration files..."  
      rm -rf "$CONFIG_DIR"  
    fi  
  fi  
    
  echo "✅ Uninstallation complete!"  
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
    echo "Unknown command: $1"  
    echo ""  
    show_help  
    exit 1  
    ;;  
esac
