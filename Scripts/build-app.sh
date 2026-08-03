#!/bin/bash
#
# Builds DelayedCmdQ.app into ./build.
#
#   ./Scripts/build-app.sh              native architecture
#   UNIVERSAL=1 ./Scripts/build-app.sh  arm64 + x86_64
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build"
APP="$BUILD_DIR/DelayedCmdQ.app"
BUNDLE_ID="com.minjun.delayedcmdq"

cd "$ROOT"

BUILD_ARGS=(build -c release --disable-sandbox)
if [[ "${UNIVERSAL:-0}" == "1" ]]; then
  BUILD_ARGS+=(--arch arm64 --arch x86_64)
fi

echo "==> Compiling"
swift "${BUILD_ARGS[@]}"

BINARY="$(swift "${BUILD_ARGS[@]}" --show-bin-path)/DelayedCmdQ"
if [[ ! -x "$BINARY" ]]; then
  echo "error: binary not found at $BINARY" >&2
  exit 1
fi

echo "==> Assembling bundle"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BINARY" "$APP/Contents/MacOS/DelayedCmdQ"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "==> Rendering icon"
if swift "$ROOT/Scripts/MakeIcon.swift" "$APP/Contents/Resources" >/dev/null; then
  echo "    AppIcon.icns"
else
  echo "    skipped (icon rendering failed)" >&2
fi

echo "==> Signing (ad hoc)"
codesign --force --sign - --identifier "$BUNDLE_ID" --timestamp=none "$APP"
codesign --verify --deep --strict "$APP"

echo
echo "Built $APP"
echo "Install with:  cp -R \"$APP\" /Applications/"
