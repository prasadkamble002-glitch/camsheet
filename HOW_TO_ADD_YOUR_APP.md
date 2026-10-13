# How to add YOUR app — non-coder guide

You don't need to code. You describe, AI builds. Follow these steps.

## Step 0 — What you need
- Your PC tool folder (e.g. `D:\CAD Automation\RENUMBER\RENUMBER v1`)
- This `turn app` folder
- Phone that allows "Install unknown apps" (we enable it below)

## Step 1 — Tell AI to convert (copy-paste this)
```
In "D:\Research for projects\turn app", add my PC tool as a phone app:

- PC folder: D:\CAD Automation\RENUMBER\RENUMBER v1
- Main logic file: renumber.py (function renumber_text)
- App name: renumber2 (or your choice)
- Follow turn-app pattern: single offline index.html in apps/<name>/
- Keep numbers/behavior identical to Python version
- Update apps.json with the new app
```

AI will create `apps/<name>/index.html`. Test it first on PC:
double-click the file → it opens in Chrome → try your real files.

## Step 2 — Build the APK (pick A or B)

### A. Cloud build (no install, easiest)
1. Create free GitHub account → new repo → upload this `turn app` folder.
2. Open `apps.json` on GitHub, change `"active": "renumber"` to your app name. Commit.
3. Click `Actions` tab → latest run → download `app-debug-apk` → you get `.apk`.
4. Send APK to phone (WhatsApp to yourself / Google Drive / USB).

### B. PC build (works offline after first setup)
1. In this folder, right-click `tools/Setup-Android.ps1` → **Run with PowerShell**.
   Wait ~10-20 min (downloads Java 17 + Android SDK + Gradle once).
2. Right-click `tools/Build-APK.ps1` → **Run with PowerShell**.
   It asks which app (default: `renumber`) → builds → APK in `out/` folder.
3. Copy APK to phone.

## Step 3 — Install on phone
1. Copy APK to phone.
2. Tap the APK → if blocked, tap **Settings → Allow from this source** → Install.
3. Open app → works offline (airplane mode OK for renumber/splitter).

## FAQ (non-coder answers)
- **Will my .exe run on phone?** No. That's why we rebuild logic as web page. Same result, different engine.
- **Do I need Android Studio?** No. Our scripts download only the builder parts (~1GB), no Studio.
- **Do I need Play Store?** No. APK installs directly (sideload).
- **Can phone read my .ptp/.MPF files?** Yes — app has file picker. On Android 11+ it reads files you pick.
- **Word/Excel export (CAMSHEET/BOM)?** Phone version saves HTML/TXT directly; full .docx/.xlsx needs extra work — ask AI per app.
- **3D viewer (VMC)?** Phone gets 2D canvas first; 3D later.
- **Is it safe?** Yes — apps work offline, no data leaves phone (unless YOUR app needs internet).

## What to send AI for each conversion
1. PC folder path
2. Main `.py` file + what buttons your PC app has (screenshot helps)
3. One sample input file + what correct output looks like
4. Any password/lock behavior (e.g. `auth_gate.py`)

AI handles the rest.
