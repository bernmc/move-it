#!/bin/zsh
# Build "Move It.app" from main.swift. Usage:
#   ./build.sh            build only (macos/build/Move It.app)
#   ./build.sh --install  build and copy to ~/Applications, then launch
set -e
cd "$(dirname "$0")"

APP="build/Move It.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/Info.plist"

echo "Compiling…"
# Pin the deployment target: the beta toolchain otherwise targets a newer
# macOS than the installed one and Launch Services refuses to open the app.
# Universal binary so it runs on both Apple Silicon and Intel Macs.
swiftc -O -swift-version 5 -target arm64-apple-macos13.0  main.swift -o "$APP/Contents/MacOS/moveit-arm64"
swiftc -O -swift-version 5 -target x86_64-apple-macos13.0 main.swift -o "$APP/Contents/MacOS/moveit-x86_64"
lipo -create -output "$APP/Contents/MacOS/Move It" "$APP/Contents/MacOS/moveit-arm64" "$APP/Contents/MacOS/moveit-x86_64"
rm "$APP/Contents/MacOS/moveit-arm64" "$APP/Contents/MacOS/moveit-x86_64"

codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "$1" == "--install" ]]; then
  mkdir -p ~/Applications
  # Quit a running copy so the binary can be replaced cleanly.
  pkill -x "Move It" 2>/dev/null || true
  sleep 1
  rm -rf ~/Applications/"Move It.app"
  ditto "$APP" ~/Applications/"Move It.app"
  echo "Installed to ~/Applications/Move It.app — launching…"
  open ~/Applications/"Move It.app"
fi
