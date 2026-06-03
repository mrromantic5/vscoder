#!/usr/bin/env bash
# VScoder Local Development Setup
set -e

echo "🔧 VScoder Setup"
echo "================"

# 1. Editor bundle
echo ""
echo "📦 Building CodeMirror 6 editor bundle..."
cd editor_src
npm install
npm run build
cd ..
echo "✅ Editor bundle built → assets/editor/editor.bundle.js"

# 2. JetBrains Mono fonts
echo ""
echo "🔤 Downloading JetBrains Mono fonts..."
mkdir -p assets/fonts
BASE="https://github.com/JetBrains/JetBrainsMono/raw/master/fonts/ttf"
curl -sL "$BASE/JetBrainsMono-Regular.ttf" -o assets/fonts/JetBrainsMono-Regular.ttf
curl -sL "$BASE/JetBrainsMono-Bold.ttf"    -o assets/fonts/JetBrainsMono-Bold.ttf
curl -sL "$BASE/JetBrainsMono-Italic.ttf"  -o assets/fonts/JetBrainsMono-Italic.ttf
echo "✅ Fonts downloaded"

# 3. Flutter deps
echo ""
echo "🐦 Getting Flutter dependencies..."
flutter pub get
echo "✅ Flutter ready"

echo ""
echo "🚀 Setup complete! Run: flutter run"
