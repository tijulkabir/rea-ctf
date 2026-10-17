# ============================================================
# REA // 1-Click Environment Bootstrap (Windows PowerShell)
# Prepares the REA environment for both Modern and CTF modes
# Supports auto-downloading Ghidra & auto-detecting IDA / Binja
# ============================================================

[CmdletBinding()]
param(
    [switch]$AutoDownload = $false
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   REA // TWO-MODE REVERSE ENGINEERING BOOTSTRAP" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Check Node.js
Write-Host "`n[1/6] Checking Node.js..." -ForegroundColor Yellow
$nodeVer = node -v 2>$null
if (-not $nodeVer) {
    Write-Host "[-] Node.js is not installed. Please install Node.js 22 or 24." -ForegroundColor Red
    exit 1
}
Write-Host "[+] Node.js detected: $nodeVer" -ForegroundColor Green

# 2. Check Java JDK (for Ghidra)
Write-Host "`n[2/6] Checking Java JDK..." -ForegroundColor Yellow
$javaRaw = (java -version 2>&1 | Out-String)
$javaOk = $false
if ($javaRaw -match 'version "([0-9]+)') {
    $major = [int]$matches[1]
    if ($major -ge 21) {
        $javaOk = $true
        Write-Host "[+] Java JDK $major detected (compatible with Ghidra)." -ForegroundColor Green
    } else {
        Write-Host "[!] Java version $major detected, but Ghidra requires JDK 21+." -ForegroundColor DarkYellow
    }
}

if (-not $javaOk) {
    Write-Host "[!] Java JDK 21+ not found in PATH." -ForegroundColor DarkYellow
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        $installJava = $AutoDownload
        if (-not $installJava -and [Environment]::UserInteractive) {
            $response = Read-Host "Would you like to install Eclipse Adoptium Temurin JDK 21 via winget? (y/N)"
            if ($response -match "^[yY]") { $installJava = $true }
        }
        if ($installJava) {
            Write-Host "[*] Installing Temurin JDK 21 via winget..." -ForegroundColor Cyan
            winget install EclipseAdoptium.Temurin.21.JDK --accept-source-agreements --accept-package-agreements --silent
            Write-Host "[+] JDK installed. Restart terminal if PATH is not updated." -ForegroundColor Green
        }
    }
}

# 3. Locate or Auto-Download Ghidra
Write-Host "`n[3/6] Locating Ghidra installation..." -ForegroundColor Yellow
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ghidraCandidates = @(
    $env:GHIDRA_INSTALL_DIR,
    (Join-Path $scriptDir "..\ghidra"),
    (Join-Path $scriptDir "ghidra"),
    "C:\tools\ghidra",
    "C:\Program Files\ghidra"
)

$foundGhidra = $null
foreach ($cand in $ghidraCandidates) {
    if ($cand -and (Test-Path (Join-Path $cand "Ghidra\application.properties"))) {
        $foundGhidra = (Resolve-Path $cand).Path
        break
    }
}

if ($foundGhidra) {
    Write-Host "[+] Ghidra located at: $foundGhidra" -ForegroundColor Green
    $env:GHIDRA_INSTALL_DIR = $foundGhidra
    [Environment]::SetEnvironmentVariable("GHIDRA_INSTALL_DIR", $foundGhidra, "User")
} else {
    Write-Host "[!] Ghidra not found in standard paths." -ForegroundColor DarkYellow
    $targetGhidraDir = (Join-Path $scriptDir "..\ghidra")
    
    $downloadGhidra = $AutoDownload
    if (-not $downloadGhidra -and [Environment]::UserInteractive) {
        $response = Read-Host "Would you like to automatically download official Ghidra 12.1.4 release? (y/N)"
        if ($response -match "^[yY]") { $downloadGhidra = $true }
    }
    
    if ($downloadGhidra) {
        Write-Host "[*] Downloading official Ghidra 12.1.4 PUBLIC from GitHub..." -ForegroundColor Cyan
        $zipUrl = "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.1.4_build/ghidra_12.1.4_PUBLIC_20241029.zip"
        $zipTemp = Join-Path $env:TEMP "ghidra_12.1.4.zip"
        
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipTemp
        Write-Host "[*] Extracting Ghidra to $targetGhidraDir ..." -ForegroundColor Cyan
        
        $tempExtract = Join-Path $env:TEMP "ghidra_extract"
        if (Test-Path $tempExtract) { Remove-Item -Recurse -Force $tempExtract }
        Expand-Archive -Path $zipTemp -DestinationPath $tempExtract -Force
        
        $innerGhidra = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
        if ($innerGhidra) {
            if (-not (Test-Path $targetGhidraDir)) { New-Item -ItemType Directory -Path $targetGhidraDir | Out-Null }
            Copy-Item -Path (Join-Path $innerGhidra.FullName "*") -Destination $targetGhidraDir -Recurse -Force
            Remove-Item -Recurse -Force $tempExtract
            Remove-Item -Force $zipTemp
            
            $foundGhidra = (Resolve-Path $targetGhidraDir).Path
            $env:GHIDRA_INSTALL_DIR = $foundGhidra
            [Environment]::SetEnvironmentVariable("GHIDRA_INSTALL_DIR", $foundGhidra, "User")
            Write-Host "[+] Ghidra 12.1.4 installed at: $foundGhidra" -ForegroundColor Green
        }
    } else {
        Write-Host "[!] Skipping Ghidra download. Set GHIDRA_INSTALL_DIR manually or clone ghidra next to rea." -ForegroundColor DarkYellow
    }
}

# 4. Detect Alternative Engines (IDA Pro / Free, Binary Ninja)
Write-Host "`n[4/6] Inspecting alternative reverse engineering engines..." -ForegroundColor Yellow

# 4a. IDA Pro / IDA Free detection
$idaCandidates = @(
    (Get-Item "C:\Program Files\IDA Pro*" -ErrorAction SilentlyContinue),
    (Get-Item "C:\Program Files\IDA Free*" -ErrorAction SilentlyContinue),
    (Get-Item "C:\Program Files (x86)\IDA*" -ErrorAction SilentlyContinue)
)
$foundIda = $idaCandidates | Select-Object -First 1

$configDir = Join-Path $scriptDir "config"
if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir | Out-Null }
$idaConfigFile = Join-Path $configDir "ida-mcp.json"

if ($foundIda) {
    Write-Host "[+] IDA detected at: $($foundIda.FullName)" -ForegroundColor Green
    # Generate default attached-mode MCP config if not existing
    if (-not (Test-Path $idaConfigFile)) {
        $idaConfigJson = @"
{
  "mode": "attached",
  "protocol": "native",
  "url": "http://127.0.0.1:13337/mcp"
}
"@
        Set-Content -Path $idaConfigFile -Value $idaConfigJson -Encoding utf8
        Write-Host "    -> Generated template IDA config: $idaConfigFile" -ForegroundColor Cyan
        Write-Host "    -> To activate: `$env:REA_IDA_MCP_CONFIG = '$idaConfigFile'; `$env:REA_ANALYSIS_PROVIDER = 'ida'" -ForegroundColor DarkGray
    }
} else {
    Write-Host "[-] IDA Pro / Free not detected in standard Program Files paths." -ForegroundColor DarkGray
}

# 4b. Binary Ninja detection
$binjaCandidates = @(
    "C:\Program Files\Vector35\BinaryNinja",
    "$env:LOCALAPPDATA\Vector35\BinaryNinja"
)
$foundBinja = $null
foreach ($bPath in $binjaCandidates) {
    if (Test-Path $bPath) {
        $foundBinja = $bPath
        break
    }
}
$binjaPython = python -c "import binaryninja; print('ok')" 2>$null

if ($foundBinja -or ($binjaPython -eq "ok")) {
    $loc = if ($foundBinja) { $foundBinja } else { "Python site-packages" }
    Write-Host "[+] Binary Ninja detected ($loc)." -ForegroundColor Green
} else {
    Write-Host "[-] Binary Ninja not detected." -ForegroundColor DarkGray
}

# 5. Install dependencies and compile REA
Write-Host "`n[5/6] Installing dependencies and building REA runtime..." -ForegroundColor Yellow
npm ci
npm run build:cached

# Ensure Windows native manifest exists
if (Test-Path "native\windows\build\rea-windows-x64.node") {
    node -e '
    const fs = require("fs");
    const crypto = require("crypto");
    const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
    const bytes = fs.readFileSync("native/windows/build/rea-windows-x64.node");
    const meta = {
      packageVersion: pkg.version,
      platform: "win32",
      architecture: "x64",
      abiVersion: 1,
      nodeApiVersion: 8,
      artifact: "rea-windows-x64.node",
      artifactSha256: crypto.createHash("sha256").update(bytes).digest("hex")
    };
    fs.writeFileSync("native/windows/build/manifest.json", JSON.stringify(meta, null, 2) + "\n");
    '
}

# 6. Health Check
Write-Host "`n[6/6] Running doctor health check..." -ForegroundColor Yellow
npm run ctf doctor

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "[+] BOOTSTRAP COMPLETE! REA is ready in both Modern & CTF modes." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  - CTF Mode:    npm run ctf -- <command> [binary]" -ForegroundColor Cyan
Write-Host "  - Modern Mode: rea <command> [target]" -ForegroundColor Cyan
if ($foundIda) {
    Write-Host "  - IDA Mode:    `$env:REA_IDA_MCP_CONFIG = '$idaConfigFile'; rea doctor --provider ida" -ForegroundColor Yellow
}
