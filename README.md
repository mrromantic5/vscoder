# VScoder — Professional Mobile Code Editor

> A premium, SaaS-grade mobile code editor built with Flutter and CodeMirror 6.
> Supports 25+ languages, in-app project management, device file I/O, HTML/JS runner, terminal, and console — 100% offline.

---

## Features

| Feature | Status |
|---|---|
| 25+ languages with unique colors | ✅ |
| CodeMirror 6 editor (autocomplete, folding, bracket matching) | ✅ |
| In-app project & virtual filesystem (SQLite) | ✅ |
| Open / Save files from device storage | ✅ |
| Real-time auto-save while typing | ✅ |
| Multi-tab editor | ✅ |
| Run HTML / CSS / JS offline | ✅ |
| Run Markdown with preview | ✅ |
| Terminal with built-in commands | ✅ |
| Real-time Console (errors, logs, warnings) | ✅ |
| Mobile control icons bar (brackets, semicolons, etc.) | ✅ |
| Copy / Paste / Select All | ✅ |
| Find & Replace | ✅ |
| Go to Line | ✅ |
| Font size & tab size settings | ✅ |
| 100% offline | ✅ |
| GitHub Actions APK + AAB CI/CD | ✅ |

---

## Quick Start — GitHub Deploy

### 1. Fork or push this repo to GitHub

```bash
git clone https://github.com/yourname/vscoder
cd vscoder
git remote set-url origin https://github.com/YOUR_USERNAME/vscoder.git
git push -u origin main
```

### 2. GitHub Actions will automatically:
1. Install Node.js and build the CodeMirror 6 bundle
2. Download JetBrains Mono fonts
3. Run `flutter pub get`
4. Build `app-arm64-v8a-release.apk` + `app-armeabi-v7a-release.apk`
5. Build `app-release.aab`
6. Create a GitHub Release with all files attached

> ⚡ **First build takes ~12 minutes.** Subsequent builds use caching (~6 min).

---

## Play Store Signing Setup (Optional but required for Play Store)

### Step 1 — Generate a keystore locally

```bash
keytool -genkey -v \
  -keystore vscoder-release.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias vscoder
```

### Step 2 — Base64 encode the keystore

```bash
# macOS / Linux
base64 -i vscoder-release.jks | tr -d '\n'

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("vscoder-release.jks"))
```

### Step 3 — Add GitHub Secrets

Go to your repo → **Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Value |
|---|---|
| `KEYSTORE_BASE64` | Base64 string from Step 2 |
| `STORE_PASSWORD` | Your keystore password |
| `KEY_PASSWORD` | Your key password |
| `KEY_ALIAS` | `vscoder` (or your alias) |

### Step 4 — Push and let CI build a signed release

---

## Local Development

### Prerequisites
- Flutter 3.24+ (`flutter --version`)
- Node.js 20+ (`node --version`)
- Android SDK

### Setup

```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Build the CodeMirror 6 editor bundle
cd editor_src
npm install
npm run build
cd ..

# 3. Download JetBrains Mono fonts (or skip — system monospace will be used)
mkdir -p assets/fonts
# Download from https://github.com/JetBrains/JetBrainsMono/releases
# Place JetBrainsMono-Regular.ttf, Bold.ttf, Italic.ttf in assets/fonts/

# 4. Run on connected Android device
flutter run
```

---

## Project Structure

```
vscoder/
├── .github/workflows/build.yml     # CI/CD pipeline
├── editor_src/                     # CodeMirror 6 source
│   ├── src/main.js                 # CM6 setup + Flutter bridge
│   └── package.json                # npm build config
├── assets/
│   ├── editor/
│   │   ├── index.html              # Editor WebView host
│   │   └── editor.bundle.js        # Built by npm (or CI)
│   ├── runner/
│   │   └── runner.html             # Code execution sandbox
│   └── fonts/                      # JetBrains Mono (downloaded by CI)
├── lib/
│   ├── main.dart                   # Entry point
│   ├── app.dart                    # MaterialApp + routes
│   ├── core/
│   │   ├── database/               # SQLite (projects, files, dirs)
│   │   ├── models/                 # Project, VFile, VDirectory
│   │   ├── providers/              # ProjectProvider, EditorProvider, ConsoleProvider
│   │   └── services/               # File I/O, execution engine, local server
│   ├── features/
│   │   ├── splash/                 # Animated splash screen
│   │   ├── projects/               # Project dashboard
│   │   ├── editor/                 # Editor screen + WebView + tabs
│   │   ├── explorer/               # File tree sidebar
│   │   ├── terminal/               # Terminal panel
│   │   ├── console/                # Console/log panel
│   │   ├── runner/                 # Code runner panel
│   │   └── settings/               # App settings
│   └── shared/
│       ├── theme/                  # AppTheme + LanguageColors
│       └── widgets/                # GlassCard, VSBadge
└── android/                        # Android config
```

---

## Language Support

| Language | Color | Extension |
|---|---|---|
| JavaScript | 🟡 Golden | .js .mjs |
| TypeScript | 🔵 Royal Blue | .ts |
| Python | 🔵 Sky Blue | .py |
| Dart | 🩵 Cyan | .dart |
| Java | 🟠 Terracotta | .java |
| Kotlin | 🟣 Violet | .kt |
| Swift | 🟠 Coral | .swift |
| C/C++ | ⚫ Steel | .c .cpp |
| Go | 🩵 Aqua | .go |
| Rust | 🔴 Burnt Orange | .rs |
| PHP | 🟣 Indigo | .php |
| Ruby | 🔴 Crimson | .rb |
| HTML | 🔴 Orange-Red | .html |
| CSS | 🔵 Blue | .css |
| SCSS | 🩷 Pink | .scss |
| SQL | 🟡 Amber | .sql |
| Shell | 🟢 Forest Green | .sh |
| JSON | 🟢 Sage | .json |
| YAML | 🟡 Amber | .yaml |
| Markdown | 🔵 Slate | .md |
| XML | 🩵 Teal | .xml |
| Vue | 🟢 Emerald | .vue |
| + more... | | |

---

## Architecture

```
Flutter App
├── UI Layer (Material 3 Dark Theme)
│   ├── Splash → Projects Home → Editor Screen
│   └── Editor Screen
│       ├── TopToolbar (undo/redo/save/run/search)
│       ├── TabBar (multi-file tabs with language color)
│       ├── ExplorerPanel (file tree, create/delete)
│       ├── EditorWebView (CodeMirror 6 via flutter_inappwebview)
│       ├── ControlIconsBar (brackets, symbols for mobile)
│       └── BottomPanels (Console | Terminal | Runner)
│
├── State Layer (Provider)
│   ├── ProjectProvider → SQLite CRUD
│   ├── EditorProvider  → Tabs, cursor, UI panels
│   └── ConsoleProvider → Logs, terminal output
│
├── Data Layer (SQLite)
│   ├── projects table
│   ├── directories table
│   └── vfiles table
│
└── Services
    ├── FileSystemService   → dart:io + file_picker
    ├── ExecutionEngine     → Language-to-runner mapping
    ├── LocalServerService  → shelf HTTP server
    └── LanguageDetector    → Extension → language mapping
```

---

## Supported Run Types

| Language | How it runs |
|---|---|
| HTML | Full document render in WebView |
| CSS | Injected into runner WebView |
| JavaScript | Executed in runner WebView |
| JSON | Pretty-printed in WebView |
| Markdown | Rendered as HTML preview |
| Others | Terminal message to compile manually |

---

## Contributing

PRs welcome! Key areas for improvement:
- [ ] Add more language support via `@codemirror/legacy-modes`
- [ ] Prettier integration for code formatting
- [ ] Git integration (status, diff, commit)
- [ ] Piston API integration for Python/Java execution
- [ ] LSP (Language Server Protocol) support

---

## License

MIT © VScoder / Tech Lyfe Team
