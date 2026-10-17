# rea-ctf

A terminal-first reverse engineering toolchain for CTFs and application analysis, built on top of [morluto/rea](https://github.com/morluto/rea).

---

## Background & Motivation

I am a 2nd-year Computer Science student focusing on systems programming, operating systems, and competitive CTF reverse engineering. 

The upstream REA project by morluto provides a Model Context Protocol (MCP) server designed for AI coding assistants to analyze software across native binaries, Electron, Android, and .NET. 

While testing it on real-world CTF challenges, I realized that spinning up heavy GUI decompiler suites (like full Ghidra or IDA) on a laptop or inside a Kali VM during a time-limited contest causes unnecessary friction. I wanted a fast, terminal-native workflow that gives me:
1. Instant binary header, section, and architecture triage from the shell.
2. Direct headless Ghidra decompilation and disassembly dumped to `stdout`.
3. Quick string queries and call-site cross-references (`xrefs`).
4. Automated Python 3 solver scaffolding with `pwntools` and `z3-solver` boilerplate.
5. Zero-configuration deployment that works on both Windows development boxes and Kali Linux competition VMs without manual path tweaking.

This fork (`rea-ctf`) introduces a dedicated CTF fast-path CLI (`npm run ctf`), multi-platform engine auto-discovery, and reproducible 1-click bootstrap scripts while keeping the full-stack application analysis features of the original REA intact.

---

## System Design & The Two Modes

The repository operates in two distinct modes depending on the target problem:

```text
rea-ctf Architecture
│
├── Mode A: CTF Binary Solver (scripts/ctf.mjs)
│   ├── Target: Executables (ELF, PE, Mach-O, raw shellcode)
│   ├── Engine: Headless NSA Ghidra / Disassembly
│   └── Outputs: Clean stdout C code, ASM listings, Z3 solver templates
│
└── Mode B: Modern Application Analysis (scripts/rea.mjs)
    ├── Target: Packaged apps & bundles
    ├── Capabilities: Electron AST recovery, Android APK analysis, .NET CIL metadata
    └── Outputs: Structural application dossier & decompiled source trees
```

---

## Quick Start & Setup

The toolchain requires **Node.js 22+** and a **Java JDK 21+** (required by Ghidra's decompiler engine).

### On Linux (Kali Linux / Ubuntu / Debian)

Kali Linux already provides Ghidra via `apt` (`/usr/share/ghidra`), which this repository automatically detects.

```bash
# 1. Clone the repository
git clone https://github.com/tijulkabir/rea-ctf.git
cd rea-ctf

# 2. Run the Linux bootstrap (checks dependencies and builds native module)
chmod +x bootstrap.sh && ./bootstrap.sh

# 3. Verify tool readiness
npm run ctf -- doctor
```

> **Note:** If Ghidra is not yet installed on your Linux machine, run `./bootstrap.sh --auto-download` to automatically fetch and unpack the official Ghidra release into the local directory.

### On Windows (PowerShell)

```powershell
# 1. Clone the repository
git clone https://github.com/tijulkabir/rea-ctf.git
cd rea-ctf

# 2. Run the PowerShell bootstrap
.ootstrap.ps1

# 3. Verify tool readiness
npm run ctf -- doctor
```

> **Note:** If Java 21+ is missing on Windows, `.ootstrap.ps1` will offer to install Eclipse Adoptium Temurin JDK 21 via `winget`. To auto-download Ghidra if missing, run `.ootstrap.ps1 -AutoDownload`.

---

## Mode A: CTF Command Reference

All CTF commands are executed through `npm run ctf -- <command>`:

```bash
npm run ctf -- <command> [binary] [arguments]
```

| Command | Usage | Description |
| :--- | :--- | :--- |
| `inspect` | `npm run ctf -- inspect <binary>` | Fast triage: format, architecture, sections, entropy, and entrypoint. |
| `decompile` | `npm run ctf -- decompile <binary> <symbol_or_hex>` | Headless decompilation directly to stdout; outputs clean C pseudocode without JSON metadata noise. |
| `disasm` | `npm run ctf -- disasm <binary> <symbol_or_hex>` | Dumps raw assembly instructions without waiting for the full decompiler pass. |
| `strings` | `npm run ctf -- strings <binary> [filter]` | Searches defined strings and literals in the binary. |
| `xrefs` | `npm run ctf -- xrefs <binary> <address>` | Finds all incoming call sites and data references to an address or symbol. |
| `template` | `npm run ctf -- template <binary> [solve.py]` | Auto-scaffolds a Python 3 solver script pre-configured with `pwntools` and `z3-solver`. |
| `doctor` | `npm run ctf -- doctor` | Verifies your local Ghidra, Java, and engine configurations. |

### Speedrun Workflow Example

```bash
# 1. Triage the unknown binary
npm run ctf -- inspect ./challenge.elf

# 2. Search for flag patterns or prompts
npm run ctf -- strings ./challenge.elf "flag{"

# 3. Decompile the validation function
npm run ctf -- decompile ./challenge.elf main

# 4. Generate an automated Z3 / pwntools solver template
npm run ctf -- template ./challenge.elf solve.py

# 5. Execute your solver
python3 solve.py
```

---

## Mode B: Modern Application Analysis

For full-stack applications, the core REA engine provides passive architecture and source extraction:

```bash
# Electron / Node.js: extract IPC channels, preload context, and endpoints
node scripts/rea.mjs analyze-javascript-application ./extracted-app

# Android: audit permissions, exported activities, and decompiled classes
node scripts/rea.mjs inspect-android-package ./target.apk

# .NET / C# Assemblies: extract CIL anchors, member tokens, and P/Invoke boundaries
node scripts/rea.mjs inspect-managed-artifact ./target.dll

# JavaScript Bundles: recover readable, formatted sources with sourcemap alignment
node scripts/rea.mjs recover-javascript-sources ./bundle.js
```

---

## Engine Auto-Discovery Details

To avoid broken paths when switching between machines, `scripts/rea.mjs` and `scripts/ctf.mjs` probe the following paths in order:

1. **Environment Variable:** `$GHIDRA_INSTALL_DIR` (if explicitly set).
2. **Local Repository Paths:** `../ghidra` or `./ghidra`.
3. **Linux System Paths:**
   - `/usr/share/ghidra` (Default Kali / Debian package location)
   - `/usr/lib/ghidra`
   - `/opt/ghidra`
   - `/usr/local/ghidra`
4. **Windows System Paths:**
   - `C:\tools\ghidra`
   - `C:\Program Files\ghidra`

### Binary Ninja & IDA Pro Support
- **Binary Ninja:** Automatically accessible if installed in `/opt/binaryninja` or available via Python bindings (`import binaryninja`).
- **IDA Pro / IDA Free 9.x:** Auto-detects local installations, generates `config/ida-mcp.json`, and links via the local MCP bridge on port `13337`.

---

## Git Hygiene & Upstream Sync

This repository is maintained as a clean, standalone fork:
- Large binaries (e.g., raw Ghidra distributions, multi-megabyte challenge samples) and `node_modules` are excluded via `.gitignore` to keep the repository lightweight (< 5 MB clone size).
- Upstream documentation is preserved in [README_UPSTREAM.md](README_UPSTREAM.md).

To pull future updates from the official `morluto/rea` project:

```bash
# Add the upstream remote (one-time setup)
git remote add upstream https://github.com/morluto/rea.git

# Pull and merge upstream changes
git fetch upstream
git merge upstream/main
```

---

## License & Attribution

- **Original REA Engine:** MIT License © [morluto](https://github.com/morluto/rea).
- **Ghidra Engine:** Apache 2.0 License © [National Security Agency](https://github.com/NationalSecurityAgency/ghidra).
- **CTF Enhancements & Bootstrappers:** MIT License © [Tijul Kabir](https://github.com/tijulkabir).
