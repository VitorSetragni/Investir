#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir/frontend"
target="${1:-macos}"
api_url="${API_BASE_URL:-https://investir-api.onrender.com}"
python3 tool/bootstrap.py
flutter pub get
flutter analyze --no-fatal-infos
flutter test
mkdir -p "$project_dir/dist"
case "$target" in
  android)
    flutter build apk --release --split-per-abi --dart-define="API_BASE_URL=$api_url"
    cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$project_dir/dist/Investir-Android-arm64.apk"
    cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "$project_dir/dist/Investir-Android-arm32.apk"
    ;;
  macos)
    flutter build macos --release --dart-define="API_BASE_URL=$api_url"
    ditto -c -k --sequesterRsrc --keepParent build/macos/Build/Products/Release/Investir.app "$project_dir/dist/Investir-macOS.zip"
    ;;
  *) echo 'Uso: bash scripts/build.sh android|macos' >&2; exit 2 ;;
esac
echo "Arquivos gerados em $project_dir/dist"
