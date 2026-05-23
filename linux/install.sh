#!/usr/bin/env bash
# Installs the Custom RR Linux desktop build into the current user's home.
# Custom RR — by Monsiu · https://github.com/monsiu/Custom-RR
#
# Usage (from the repo root after `flutter build linux --release`):
#   ./linux/install.sh           # install to ~/.local
#   ./linux/install.sh --uninstall
#
# This is a per-user install — no root required. To uninstall, re-run with
# --uninstall or delete the paths printed at the end.

set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
APP_ID='custom_rr'
APP_NAME='Custom RR'

BUNDLE_DIR="build/linux/x64/release/bundle"
TARGET_DIR="$PREFIX/share/$APP_ID"
BIN_LINK="$PREFIX/bin/$APP_ID"
DESKTOP_FILE="$PREFIX/share/applications/$APP_ID.desktop"
ICON_FILE="$PREFIX/share/icons/hicolor/512x512/apps/$APP_ID.png"

if [[ "${1:-}" == '--uninstall' ]]; then
  rm -rf "$TARGET_DIR" "$BIN_LINK" "$DESKTOP_FILE" "$ICON_FILE"
  echo "Uninstalled $APP_NAME from $PREFIX"
  exit 0
fi

if [[ ! -x "$BUNDLE_DIR/$APP_ID" ]]; then
  echo "error: $BUNDLE_DIR/$APP_ID not found. Run 'flutter build linux --release' first." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR" "$(dirname "$BIN_LINK")" \
         "$(dirname "$DESKTOP_FILE")" "$(dirname "$ICON_FILE")"

# Copy the whole bundle (binary + engine .so + data/ + lib/).
cp -r "$BUNDLE_DIR/." "$TARGET_DIR/"

# Shim in $PATH so `custom_rr` works from the terminal.
ln -sf "$TARGET_DIR/$APP_ID" "$BIN_LINK"

# Desktop entry — rewrite Exec to the absolute path so launchers find it.
sed "s|^Exec=.*|Exec=$TARGET_DIR/$APP_ID|" linux/$APP_ID.desktop > "$DESKTOP_FILE"
chmod 644 "$DESKTOP_FILE"

# Icon (reuses the launcher PNG from images/).
cp images/launcher.png "$ICON_FILE"

# Refresh the desktop database so the entry appears in app menus without
# needing a logout. Ignored if update-desktop-database isn't installed.
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$PREFIX/share/applications" >/dev/null 2>&1 || true
fi

echo "Installed $APP_NAME:"
echo "  bundle:   $TARGET_DIR"
echo "  binary:   $BIN_LINK"
echo "  desktop:  $DESKTOP_FILE"
echo "  icon:     $ICON_FILE"
echo
echo "Launch with: $APP_ID  (or find '$APP_NAME' in your app menu)"
