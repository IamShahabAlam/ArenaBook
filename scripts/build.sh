#!/usr/bin/env bash
# Release build for one client: scripts/build.sh <client> [apk|appbundle|ipa] [extra flutter args]
# The output is copied to dist/ArenaBook-<client>-<version>.<apk|aab|ipa>.
set -euo pipefail
cd "$(dirname "$0")/.."

usage() {
  echo "Usage: scripts/build.sh <client> [apk|appbundle|ipa] [extra flutter args]"
  echo "Clients:"
  for f in lib/app/config/clients/*.dart; do
    name=$(basename "$f" .dart)
    [ "$name" != "client_config" ] && echo "  $name"
  done
  exit 1
}

CLIENT=${1:-}
TARGET=${2:-apk}
[ -z "$CLIENT" ] && usage
[ -f "lib/app/config/clients/$CLIENT.dart" ] || { echo "Unknown client \"$CLIENT\"."; usage; }
case "$TARGET" in apk | appbundle | ipa) ;; *) echo "Unknown target \"$TARGET\"."; usage ;; esac
shift $(($# < 2 ? $# : 2))

VERSION=$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}')
echo "Building $CLIENT $TARGET v$VERSION ..."
flutter build "$TARGET" --release --flavor "$CLIENT" "$@"

mkdir -p dist
case "$TARGET" in
  apk) SRC="build/app/outputs/flutter-apk/app-$CLIENT-release.apk"; EXT=apk ;;
  appbundle) SRC="build/app/outputs/bundle/${CLIENT}Release/app-$CLIENT-release.aab"; EXT=aab ;;
  ipa) SRC=$(ls build/ios/ipa/*.ipa | head -1); EXT=ipa ;;
esac
OUT="dist/ArenaBook-$CLIENT-$VERSION.$EXT"
cp "$SRC" "$OUT"
echo "Done: $OUT"
