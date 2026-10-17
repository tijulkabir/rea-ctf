# REA Dual-Mode Guide: Modern App & CTF Solver

Welcome to your dual-mode **REA (Reverse Engineer Anything)** environment. This repository is configured to operate in two distinct workflows:

1. **Modern App Reversing Mode**: Analysis of Web apps, Electron, Android APKs, iOS Mach-O, Node.js applications, and complex multi-architecture bundles.
2. **CTF Rev Solver Mode**: Fast, headless binary decompilation, string extraction, cross-referencing, and automated Python/Z3 solver generation powered by local Ghidra.

---

## 🚀 Quick Start: Pulling on Any Machine

Whenever you clone or pull this repository onto a new machine (Windows, Linux, or macOS):

### Windows:
```powershell
.\bootstrap.ps1
```

### Linux / macOS:
```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

The bootstrap script will automatically:
- Verify Node.js and Java JDK 21+
- Automatically discover your Ghidra installation (checking adjacent `../ghidra` or standard paths)
- Install dependencies and compile the local runtime
- Verify health checks across all providers

---

## ⚔️ Mode 1: CTF Rev Solver Mode

Use the dedicated CTF CLI wrapper (`npm run ctf` or `node scripts/ctf.mjs`):

### 1. Inspect a Challenge Binary
```powershell
npm run ctf -- inspect <target.exe>
```
*Outputs: Architecture, base address, PE/ELF section layouts, symbol count, and string inventory.*

### 2. Decompile a Function
```powershell
npm run ctf -- decompile <target.exe> 0x140001000
```
*Outputs: Headless Ghidra decompilation / C pseudocode straight to stdout.*

### 3. Search Strings & Flags
```powershell
npm run ctf -- strings <target.exe> "CTF{"
```
*Extracts and filters hardcoded strings, stack buffers, and text references.*

### 4. Trace Cross-References
```powershell
npm run ctf -- xrefs <target.exe> 0x140001000
```
*Lists all incoming and outgoing call sites and data references.*

### 5. Generate Instant Python Z3 Solver Template
```powershell
npm run ctf -- template <target.exe> solve.py
```
*Generates an executable `solve.py` script pre-wired with `pwntools` and `z3-solver`.*

---

## 📱 Mode 2: Modern App Reversing Mode

Use standard REA CLI commands for modern platforms:

- **Android APK Analysis**:
  ```powershell
  rea inspect-android-package app.apk
  ```
- **JavaScript / Electron De-obfuscation**:
  ```powershell
  rea analyze-javascript-application /path/to/electron-app
  ```
- **Recover Bundled Web/Node Sources**:
  ```powershell
  rea recover-javascript-sources /path/to/bundle.js
  ```
- **Inspect Web Page / CDP Session**:
  ```powershell
  rea inspect-web-page http://localhost:3000
  ```

---

## 🐙 Forking & Pushing to Your GitHub

To link this repository to your personal GitHub fork and push:

```powershell
# 1. Rename original remote to upstream (for pulling updates from original repo)
git remote rename origin upstream

# 2. Add your GitHub fork as origin (replace with your GitHub username)
git remote add origin https://github.com/<YOUR_USERNAME>/rea.git

# 3. Create your custom feature or ctf branch
git checkout -b ctf-solver

# 4. Push to your fork
git push -u origin ctf-solver
```

To sync with original repo updates in the future:
```powershell
git fetch upstream
git merge upstream/main
```
