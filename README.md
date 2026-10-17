# rea-ctf

A terminal-first reverse engineering toolchain and CLI wrapper built on top of [morluto/rea](https://github.com/morluto/rea).

---

## Overview

Upstream REA is designed primarily as a Model Context Protocol (MCP) server for deep, multi-target application analysis (Electron, Android APK, .NET, native binaries). 

`rea-ctf` extends the engine with a dedicated CLI fast-path (`npm run ctf`) optimized for binary triage, CTF challenges, and headless reverse engineering. It provides direct command-line decompilation, instruction disassembly, string/xref search, and automated constraint solver scaffolding without requiring a GUI decompiler session.

### Core Capabilities

- **Headless Decompilation & Disassembly:** Runs Ghidra analysis in headless mode and outputs normalized, human-readable C pseudocode or raw x86/x64 disassembly directly to stdout.
- **Fast Binary Triage:** Extracts architecture, file format, section layout, entropy, and symbol tables from ELF, PE, and Mach-O targets.
- **Solver Scaffolding:** Generates Python 3 constraint solver templates pre-configured with `pwntools` and `z3-solver`.
- **Application Security Analysis:** Retains upstream REA capabilities for inspecting Electron ASTs, Android APK manifests/classes, .NET CIL metadata, and formatted JavaScript source maps.
- **Cross-Platform Auto-Discovery:** Detects local Ghidra installations across Linux system paths (`/usr/share/ghidra`, `/opt/ghidra`) and Windows paths without requiring manual environment variables.

---

## Installation & Setup

### Prerequisites
- **Node.js:** `^22.19.0 || ^24.11.0 || >=26.0.0`
- **Java:** JDK 21+ (required for Ghidra analysis)

### Linux (Kali / Debian / Ubuntu)
```bash
git clone https://github.com/tijulkabir/rea-ctf.git
cd rea-ctf
chmod +x bootstrap.sh && ./bootstrap.sh
```
*Note: On Kali Linux, system Ghidra (`/usr/share/ghidra`) is detected automatically. To download an official portable Ghidra release if missing, pass `--auto-download`.*

### Windows (PowerShell)
```powershell
git clone https://github.com/tijulkabir/rea-ctf.git
cd rea-ctf
.\bootstrap.ps1
```
*Note: If Java 21+ is missing, the bootstrap script can install Eclipse Temurin JDK 21 via `winget`. Pass `-AutoDownload` to fetch Ghidra automatically.*

---

## Command Reference

### CTF Mode (`scripts/ctf.mjs`)
Commands run via `npm run ctf -- <command> [binary] [args]`:

| Command | Arguments | Description |
| :--- | :--- | :--- |
| `inspect` | `<binary>` | Displays file format, architecture, sections, entropy, and entrypoint. |
| `decompile` | `<binary> <symbol_or_address>` | Decompiles target function and prints clean C pseudocode to stdout. |
| `disasm` | `<binary> <symbol_or_address>` | Dumps assembly instructions for the specified function or address range. |
| `strings` | `<binary> [query]` | Searches defined strings and literals with optional regex/text filtering. |
| `xrefs` | `<binary> <address>` | Resolves incoming and outgoing cross-references for a symbol or address. |
| `template` | `<binary> [output.py]` | Generates a starter Python solver using `pwntools` and `z3-solver`. |
| `doctor` | | Runs health diagnostics on Ghidra, Java, and engine configurations. |

#### Example Usage
```bash
# Triage unknown binary
npm run ctf -- inspect ./challenge.elf

# Search for known flag markers
npm run ctf -- strings ./challenge.elf "flag{"

# Decompile target validation function
npm run ctf -- decompile ./challenge.elf main

# Scaffold Z3 solver script
npm run ctf -- template ./challenge.elf solve.py
```

### Application Security Mode (`scripts/rea.mjs`)
For packaged applications and managed environments:

```bash
# Electron / Node.js AST and IPC analysis
node scripts/rea.mjs analyze-javascript-application ./extracted-app

# Android APK manifest, permissions, and decompilation
node scripts/rea.mjs inspect-android-package ./target.apk

# .NET / C# CIL metadata and P/Invoke boundary analysis
node scripts/rea.mjs inspect-managed-artifact ./target.dll

# JavaScript bundle source recovery and formatting
node scripts/rea.mjs recover-javascript-sources ./bundle.js
```

---

## Engine Discovery

The runtime automatically resolves analysis providers in the following order:

1. `$GHIDRA_INSTALL_DIR` environment variable (if set).
2. Local repository directories (`../ghidra` or `./ghidra`).
3. Standard Linux installation paths:
   - `/usr/share/ghidra` (Kali Linux / Debian package)
   - `/usr/lib/ghidra`
   - `/opt/ghidra`
   - `/usr/local/ghidra`
4. Standard Windows installation paths:
   - `C:\tools\ghidra`
   - `C:\Program Files\ghidra`

### Binary Ninja & IDA Pro
- **Binary Ninja:** Available via Python API if `/opt/binaryninja` is in `PYTHONPATH`.
- **IDA Pro / IDA Free 9.x:** Auto-detects local installations and bridges via `config/ida-mcp.json`.

---

## Upstream Synchronization

This repository is maintained as a downstream fork of [morluto/rea](https://github.com/morluto/rea). Original documentation is preserved in [README_UPSTREAM.md](README_UPSTREAM.md).

To pull upstream updates:
```bash
git remote add upstream https://github.com/morluto/rea.git
git fetch upstream
git merge upstream/main
```

---

## License

- **Original REA Engine:** MIT License © [morluto](https://github.com/morluto/rea)
- **Ghidra Engine:** Apache 2.0 License © [National Security Agency](https://github.com/NationalSecurityAgency/ghidra)
