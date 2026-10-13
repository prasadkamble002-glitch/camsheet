# Turn App — turn your PC software into Android apps

You make Python PC tools (CAMShet, RENUMBER, VMC Visualizer, BOM Maker...).
This folder is your **Android factory**. No coding needed — you tell AI what
your PC app does, AI puts a web version in `apps/<name>/`, then one script
builds the APK.

**Truth for non-coders (important):**
- Your Python + PySide6 apps **cannot run directly on Android**. Android does
  not run `.exe` or Python Qt.
- So we do NOT copy Python to phone. We **rebuild the same logic as an
  offline web page** (HTML + JavaScript) and wrap it in a real Android app.
- Result: same buttons/logic, works offline, installable APK, no Play Store needed.

```
turn app/
  README.md                  <- you are here
  CAMSHEET_TO_ANDROID.md     <- full playbook: how CAMSheet was converted + GitHub build diary (read before converting your next app)
  HOW_TO_ADD_YOUR_APP.md     <- simple steps for non-coders
  apps.json                  <- list of your apps
  apps/renumber/index.html   <- WORKING DEMO (your RENUMBER tool, now on phone)
  www-template/index.html    <- blank starter for next app
  template/                  <- Android wrapper (WebView, offline)
  tools/Setup-Android.ps1    <- one-click: downloads JDK17 + SDK + Gradle
  tools/Build-APK.ps1        <- one-click: builds APK for apps/<name>
  tools/Make-App.ps1         <- creates apps/<newname> from template
  .github/workflows/build-apk.yml <- cloud build (no PC setup at all)
```

## Fastest path (pick ONE)

### Option A — cloud build, nothing to install (recommended for you)
1. Put this `turn app` folder on GitHub.
2. Edit `apps.json` → set which app to build.
3. GitHub Actions builds the APK → download from Actions tab → send to phone → install.
4. See `HOW_TO_ADD_YOUR_APP.md` section A.

### Option B — build on your PC
1. Right-click `tools/Setup-Android.ps1` → Run with PowerShell (once, downloads ~1GB).
2. Right-click `tools/Build-APK.ps1` → Run with PowerShell → APK appears in `out/`.
3. Copy APK to phone (USB / WhatsApp / Drive) → tap to install.

## Try it now (2 minutes, no setup)
1. Open `apps/renumber/index.html` in Chrome on your PC — it IS the Android app UI.
2. Pick a `.ptp` / `.MPF` / `.txt` G-code file → set Start/Step/Digits → Renumber → Download.
3. Same file runs inside the phone app offline. Logic matches `renumber.py`.

## Your apps inventory (from your PC)
| PC tool | Type | Phone difficulty |
|---|---|---|
| RENUMBER (N-code) | text rewrite, byte-clean | EASY — done as demo |
| CNC Program Splitter | text split | EASY |
| CAMSheet v3/v4 | parse HTML + rules + Word + program check | DONE as demo (`apps/camsheet`) — real .docx on phone |
| VMC Toolpath Visualizer | 2D/3D plot of G-code | MEDIUM (canvas 2D works, 3D trimmed) |
| BOM Maker (STEP → XLSX) | CAD parse + Excel | HARD (STEP parsing too heavy for phone — needs simplified version) |
| DXF Fitter | curve fit + DXF | MEDIUM |
| ThumbAuth | already has android-app | DONE separately |

Start with EASY ones. Tell AI: "convert X using turn-app pattern, keep logic identical to file Y".

## Rules for AI converting your apps
1. Read the original `*.py` logic first, keep number-for-number behavior.
2. Output ONE single `index.html` (inline CSS+JS, no internet, no CDN).
3. Must work from `file://` and inside Android WebView.
4. Use `<input type=file>` + Blob download (works in WebView with our wrapper).
5. No Python, no server, no npm needed on phone.
