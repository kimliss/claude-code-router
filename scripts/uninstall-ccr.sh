#!/usr/bin/env bash
set -e

INSTALL_PATH="/usr/local/bin/ccr"

echo "🧹 Uninstalling CCR..."

if [ -f "$INSTALL_PATH" ]; then
  sudo rm "$INSTALL_PATH"
  echo "✅ Removed $INSTALL_PATH"
else
  echo "⚠️  ccr not found in $INSTALL_PATH"
fi
