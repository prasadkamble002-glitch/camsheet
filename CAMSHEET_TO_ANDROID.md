# How CAMSheet Became an Android App — conversion playbook

This document records exactly how `D:\Research for projects\CAMSheet-v4`
(Windows Python + PySide6 desktop tool, ~7,000 lines, 50 files) was turned
into `apps/camsheet/index.html` (one offline file, phone-installable APK
with nearly the same functionality). Follow the same recipe for your other
tools (RENUMBER is already done as `apps/renumber`; Splitter, VMC
Visualizer, BOM Maker are next in that order of difficulty).

Current phone release: **v1.7, versionCode 8, package `com.turnapp.camsheet`**.

---

## Part 1 — The conversion recipe (reuse for every app)

### 1. The core rule: port the logic, don't copy the program

Android cannot run your Python/Qt `.exe`. So every conversion does this:

```
PC Python logic  →  same math, rewritten in JavaScript  →  one offline index.html
       →  wrapped by template/ (real Android app)  →  APK
```

What ports 1:1 (pure functions, no screen, no files):
- Parsers, calculators, rule tables, validators, formatters

What gets rebuilt for phone (same behavior, new shape):
- File picking (`<input type=file>` instead of folder paths)
- Tables/lists instead of wide desktop grids (small screen)
- Exports that need Word/Windows (see §4)

### 2. What CAMSheet kept, piece by piece

| PC module | Phone equivalent | Verified how |
|---|---|---|
| `html_reader.py` (parse NX table, img-title fallback) | `parseNxHtml()` (DOMParser, same fallback) | 145/145 rows identical on real export |
| `html_interpreter.py` (MCS→Workpiece→ops) | `interpret()` | 135 ops, 12 fields each identical |
| `description_rules.py` (8 mappings) | `DEFAULT_DESC` + editable table | unit checks |
| `tool_rules.py` (diameter ranges, ceil, strip) | same math in JS | 15 edge cases identical |
| `program_validator.py` + `program_type_rules.py` | `checkRowProgram()` + type map | 6 compare cases + 11 helpers identical |
| `time_utils.py` (D:HH:MM:SS totals) | `parseTimeToSeconds/formatSecondsToNx` | identical incl. 4-part times |
| `process_row.format_stock()` | `formatStock()` | `5.0`→`5.00` etc. |
| `word_generator.py` policy | pure-JS stored-ZIP `.docx` writer (no libraries) | PC-vs-phone Word diff: 127 rows, all cells equal; opens in real MS Word |
| project save/load (`.camsheet` JSON) | JSON download/upload incl. drawing + compare files | round-trip tested |
| setup drawing (PDF/image) | images direct; PDFs via native bridge (§5) | PNG embed validated in Word |
| description/tool rule dialogs | editable tables in-app | same defaults as PC |

### 3. Phone-only adaptations (do these for every app)

1. **Accumulate, don't replace.** Phones can't grant a folder like PCs. File
   pickers add to a visible list (with Remove/Clear) across repeated picks.
2. **One file instead of a folder.** For bulk input, accept a `.zip`
   (pure-JS inflate lives in the page; supports stored + deflated, CRC-checked).
3. **Pinned navigator for long lists.** Sticky bar with counts
   (`✓12 ✗3 ?2`, `N above · M below`) + Prev/Next jump buttons; rows get
   green/red/amber edge colors like the PC's match highlighting.
4. **Readable decoded lines.** Raw values stay, plus a plain-language line
   (e.g. `Cutter Ø20 mm · corner R2 · NX length L100 → production 25`).
5. **Column toggles.** Defaults = PC defaults; every column toggleable;
   applies to Word + sheet + CSV + print together.
6. **Popup confirmations.** Every export/compare pops a 3-second toast
   (green = saved + filename, red = error) — the Status box alone is too far
   to scroll to on a phone.
7. **Save bridge, not blob downloads.** Android WebView silently drops
   `blob:`-URL downloads, and `window.print()` does nothing. All exports go
   through `TurnAppNative.saveFileBase64()` → Downloads folder; print goes
   through `TurnAppNative.printPage()` → system print dialog.

### 4. Honest limits (tell the user upfront, per app)

- **No real `.xlsx`, no Word-COM PDFs** on phone. Word/PDF come from our own
  writers (Word is byte-verified; print uses Android's print service).
- **PDF rendering needs the installed APK** (native bridge). In a browser it
  shows "needs the installed app" instead of failing silently.
- **Big zips (100s of MB)** should be split — phones have less memory.
- Password gates from PC (`auth_gate.py`) are intentionally dropped on phone
  (sideloaded personal use).

### 5. The wrapper (`template/`) — what it gives every app for free

`template/app/src/main/java/com/turnapp/factory/MainActivity.kt`:
- Offline WebView loading `assets/app/index.html`
- File picker incl. multi-select (`<input type=file multiple>`)
- `PdfBridge`: `pdfPageCountBase64` + `renderPdfPageBase64` (built-in
  PdfRenderer, no libraries) + `saveFileBase64` (MediaStore on Android 10+,
  legacy path + runtime permission on 8/9) + `printPage` (system dialog)
- App icon: `res/drawable/ic_launcher_fg.xml` (vector, redrawn from the PC
  `.ico`/`.svg`) + `mipmap-anydpi-v26/ic_launcher.xml` + `colors.xml`;
  referenced in the manifest. New apps get the same icon until you replace it.

### 6. Per-app checklist (copy this for the next conversion)

1. Read the PC logic files; list pure functions vs GUI/file/Word parts.
2. `tools\Make-App.ps1 -Name <name>` → `apps/<name>/index.html` from starter.
3. Port pure functions to JS (same names where possible).
4. Rebuild picking/editing/export for phone (§3).
5. **Verify like we did:** Python reference dumps → Node harness runs the
   *actual shipped file's* functions → field-by-field diff (see §8).
6. Word/output diff vs PC on identical input before calling it done.
7. Register in `apps.json` (`title`, `package com.turnapp.<name>`,
   `versionCode+1`, `src`, `portedFrom`), set `"active"`, push → cloud builds.
8. Install APK, test on real phone data (pickers, bridge, exports).

### 7. CAMSheet feature timeline (what each version added)

- **v1.0** — import NX HTML, rules, editable rows, sheet/CSV/JSON exports.
- **v1.1** — real offline `.docx`, part-file path, drawing photos, NC compare.
- **v1.2** — column toggles (PC defaults), PC-format Word parity, readable
  tool lines, accumulating program files, PDF bridge in wrapper.
- **v1.3** — `.zip` program bundles (pure-JS inflate).
- **v1.4** — inflate bugfix: distance-table base `2305`→`2049` (real CNC zips
  died with "match before start"; caught by your TOPSIDE.zip test).
- **v1.5** — PDF attached/rendered badges, PDF state in saved projects.
- **v1.6** — native save bridge (blob downloads silently failed in WebView),
  native print, pinned issue navigator, launcher icon.
- **v1.7** — 3-second toast popup on every export/compare.

### 8. Verification playbook (the method, reusable)

- Extract the shipped file's `<script>` in Node, `new Function()` it
  (syntax check), run it top-to-bottom with DOM stubs (runtime check).
- Pure-logic diffs: dump Python reference outputs to JSON, feed the same
  inputs to the JS functions, compare every field (we did 135 ops × 12
  fields + 15 helper cases + 6 compare cases).
- ZIP: cross-check against Python `zipfile` byte-for-byte (deflated, stored,
  subdirs, unicode names, 1 MB files, Windows-made zips); corrupt/truncated
  inputs must throw, never silently corrupt.
- Word: unzip in Python (`testzip` + `python-docx` cell check) AND open in
  real MS Word via COM (clean open, no repair prompt, correct tables).
- APK: open the built APK as a zip — confirm `assets/app/index.html`
  version string, new JS markers, `classes*.dex` contains bridge methods,
  icon XMLs present, label in resources.

---

## Part 2 — Build diary: the GitHub day (Option B → Option A)

### Background

`tools/Setup-Android.ps1` (Option B, local PC build) kept failing: the
Temurin JDK download URLs 404'd twice (Adoptium removes old releases —
fixed by querying `api.adoptium.net` for the current `17.0.20.1+1` zip),
the Android SDK step stalled, and PowerShell output capture broke down, so
failures were invisible. Decision: **Option A (GitHub Actions cloud build)**.

### Repo setup (prasadkamble002-glitch/camsheet)

1. Created empty repo on github.com, uploaded `turn app` via web drag-drop.
2. **Pitfall 1:** browsers skip the hidden `.github` folder on drag-drop, so
   no workflow appeared under Actions. Fix: uploaded `build-apk.yml`
   separately — but it landed at the **repo root**, where GitHub ignores it.
3. Gave the breadcrumb test: a workflow counts only at exactly
   `.github/workflows/build-apk.yml` (repo → `.github` → `workflows`).

### Granting access (the safe way — no password ever shared)

You asked "can i give access to my github?" Answer: never share passwords or
tokens. Instead:
1. Installed GitHub's official CLI: `winget install --id GitHub.cli`
2. **You** ran `gh auth login --web --git-protocol https --scopes repo,workflow`
   in your own PowerShell and completed the browser device-code flow
   yourself (code → github.com/login/device → Authorize). The token stayed
   in your Windows keyring; only CLI access with `repo` + `workflow` scopes.
3. To revoke anytime: `gh auth logout`.

### What was pushed, and the three build failures

With `gh` working, the fix for the upload mess was direct: `git init`,
staged all 22 real files (workflow at the right path + the `apps/`,
`template/`, `tools/` folders the web upload had dropped), committed, and
force-pushed over the botched upload. Then `gh workflow run build-apk.yml`
and watched it. It failed three times, each a real bug, each fixed:

1. **`android-actions/setup-android@v3` is broken** — it installs Google's
   long-removed `tools` package (`Failed to find package 'tools'`, exit 1).
   Fix: dropped that action; the workflow now installs only
   `platform-tools`, `platforms;android-34`, `build-tools;34.0.0` via
   `sdkmanager` directly.
2. **`isMinifyEnabled = false` rejected** — Kotlin-DSL syntax in a Groovy
   `build.gradle` (`Could not set unknown property`). Fix: `minifyEnabled
   false`. (This bug also sat in the local `tools\Build-APK.ps1` path —
   same template file, fixed for both.)
3. **SDK location conflict** — our `ANDROID_HOME=/tmp/android-sdk` clashed
   with the runner's preset `ANDROID_SDK_ROOT=/usr/local/lib/android/sdk`
   (AGP refuses two SDK paths). Fix: use the runner's preinstalled SDK,
   set nothing. Also moved `setup-java@v4`→`v5` per the deprecation notice.

Fourth run: **success** (~1m15s). Downloaded the artifact with `gh run
download`, verified the APK contents (HTML version string, bridge methods
in `classes3.dex`, icon XMLs, label), saved as `D:\CAMSheet-v1.5.apk`.
Later feature builds (v1.6, v1.7) followed the same loop: edit → commit →
push → `gh workflow run` → watch → download → verify → copy to `D:\`.

### The steady-state loop (use this from now on)

```powershell
# 0. one-time per PC: done (gh installed + logged in)
cd "D:\Research for projects\turn app"

# 1. edit apps/<name>/index.html, template/, or apps.json, then:
git add -A
git -c core.autocrlf=false commit -m "Describe the change"
git push origin main

# 2. build (auto-starts on push for apps/**, template/**, apps.json;
#    run manually for any other change):
$env:PATH = "C:\Program Files\GitHub CLI;" + $env:PATH
gh workflow run build-apk.yml --repo prasadkamble002-glitch/camsheet --ref main

# 3. watch (3–6 min), then download:
gh run watch <RUN_ID> --repo prasadkamble002-glitch/camsheet --exit-status --interval 20
gh run download <RUN_ID> --repo prasadkamble002-glitch/camsheet --dir <OUT_DIR>

# 4. copy out/app-debug-apk/app-debug.apk to phone, install over old version
```

Notes:
- `apps.json` `"active"` decides which app the next build produces.
- Workflow file: `.github/workflows/build-apk.yml` (self-contained: Temurin
  JDK 17, runner SDK packages, Gradle 8.7, template staging, package-ID
  rewrite, `assembleDebug`, artifact upload).
- Artifacts expire (GitHub default 90 days) — keep a copy of each release
  APK on your PC (`D:\CAMSheet-vX.Y.apk` pattern).
- `gh auth logout` revokes this PC's access whenever you want.
