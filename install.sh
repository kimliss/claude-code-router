#!/bin/bash  
  
set -e  
  
VERSION=${1:-latest}  
INSTALL_DIR="$HOME/.claude-code-router-bin"  
BIN_DIR="/usr/local/bin"  
  
echo "Installing claude-code-router..."  
  
# Download release  
if [ "$VERSION" = "latest" ]; then  
  DOWNLOAD_URL="https://github.com/kimliss/claude-code-router/releases/latest/download/claude-code-router-macos.tar.gz"  
else  
  DOWNLOAD_URL="https://github.com/kimliss/claude-code-router/releases/download/$VERSION/claude-code-router-macos.tar.gz"  
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
