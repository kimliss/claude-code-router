
#!/usr/bin/env bash
set -e

REPO="kimliss/claude-code-router"
TAG=${1:-latest}
INSTALL_DIR="/usr/local/bin"

echo "🚀 Installing CCR (${TAG}) ..."

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

if [ "$TAG" = "latest" ]; then
  URL="https://github.com/$REPO/releases/latest/download/ccr-main.tar.gz"
else
  URL="https://github.com/$REPO/releases/download/${TAG}/ccr-main.tar.gz"
fi

echo "⬇️  Downloading from $URL"
curl -L -o ccr.tar.gz "$URL"
tar -xzf ccr.tar.gz

# 复制 CLI
chmod +x dist/cli.js
sudo ln -sf "$(pwd)/dist/cli.js" "$INSTALL_DIR/ccr"

echo "✅ CCR installed to $INSTALL_DIR/ccr"
echo "➡️  Try: ccr --help"
