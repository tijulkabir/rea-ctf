#!/usr/bin/env bash
set -e

echo "============================================================"
echo "   REA // TWO-MODE REVERSE ENGINEERING BOOTSTRAP (UNIX)"
echo "============================================================"

# 1. Check Node
echo "[1/5] Checking Node.js..."
node -v

# 2. Check Java
echo "[2/5] Checking Java JDK..."
if ! command -v java >/dev/null 2>&1; then
    echo "[!] Java not found in PATH. Ghidra requires JDK 21+."
else
    java -version 2>&1 | head -n 2
fi

# 3. Locate or Download Ghidra
echo "[3/5] Locating Ghidra..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOUND_GHIDRA=""
for CAND in "$GHIDRA_INSTALL_DIR" "$SCRIPT_DIR/../ghidra" "$SCRIPT_DIR/ghidra" "/usr/share/ghidra" "/usr/lib/ghidra" "/opt/ghidra" "/usr/local/ghidra" "$HOME/ghidra"; do
    if [ -n "$CAND" ] && [ -f "$CAND/Ghidra/application.properties" ]; then
        FOUND_GHIDRA="$(cd "$CAND" && pwd)"
        export GHIDRA_INSTALL_DIR="$FOUND_GHIDRA"
        echo "[+] Found Ghidra at: $GHIDRA_INSTALL_DIR"
        break
    fi
done

if [ -z "$FOUND_GHIDRA" ]; then
    echo "[!] Ghidra not found in standard paths."
    if [ "$1" = "--auto-download" ] || [ -n "$AUTO_DOWNLOAD" ]; then
        echo "[*] Downloading official Ghidra 12.1.4 PUBLIC from GitHub..."
        ZIP_URL="https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.1.4_build/ghidra_12.1.4_PUBLIC_20241029.zip"
        TEMP_ZIP="/tmp/ghidra_12.1.4.zip"
        TEMP_EXTRACT="/tmp/ghidra_extract"
        curl -fSL "$ZIP_URL" -o "$TEMP_ZIP"
        mkdir -p "$TEMP_EXTRACT"
        unzip -q "$TEMP_ZIP" -d "$TEMP_EXTRACT"
        TARGET_DIR="$SCRIPT_DIR/../ghidra"
        mkdir -p "$TARGET_DIR"
        mv "$TEMP_EXTRACT"/*/* "$TARGET_DIR"/
        rm -rf "$TEMP_EXTRACT" "$TEMP_ZIP"
        export GHIDRA_INSTALL_DIR="$(cd "$TARGET_DIR" && pwd)"
        echo "[+] Ghidra installed to: $GHIDRA_INSTALL_DIR"
    else
        echo "[!] To auto-download Ghidra, run: ./bootstrap.sh --auto-download"
    fi
fi

# 4. Engine Detection (IDA / Binary Ninja)
echo "[4/5] Inspecting engines..."
mkdir -p "$SCRIPT_DIR/config"
if [ ! -f "$SCRIPT_DIR/config/ida-mcp.json" ]; then
    cat << 'EOF' > "$SCRIPT_DIR/config/ida-mcp.json"
{
  "mode": "attached",
  "protocol": "native",
  "url": "http://127.0.0.1:13337/mcp"
}
EOF
fi

# 5. Build REA runtime
echo "[5/5] Building REA runtime..."
npm ci
npm run build:cached
npm run ctf doctor

echo ""
echo "[+] REA Bootstrap Complete!"
echo "  - CTF Mode:    npm run ctf -- <command> [binary]"
echo "  - Modern Mode: node scripts/rea.mjs <command> [target]"
