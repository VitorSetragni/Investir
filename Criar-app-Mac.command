#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
echo 'Gerando o aplicativo Investir para macOS.'
echo 'É necessário ter Flutter 3.38.5+, Xcode e CocoaPods instalados.'
bash scripts/build.sh macos
open dist
