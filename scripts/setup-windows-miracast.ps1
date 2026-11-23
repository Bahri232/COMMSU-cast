<#
.SYNOPSIS
    One-Time Windows Setup Script for ComSSU Cast (CS Society Display)
    University of Makeni (UniMak) — Computer Science Students' Society (ComSSU)

.DESCRIPTION
    Prepares a Windows 10/11 PC (such as the 85-inch interactive display PC) to act as a
    full Wi-Fi Direct + Miracast, Apple AirPlay, Google Cast, and DLNA receiver:
      1. Verifies Administrator privileges and checks if the Wi-Fi driver supports Miracast.
      2. Checks and installs the Windows Wireless Display optional feature if missing:
         DISM /Online /Add-Capability /CapabilityName:App.WirelessDisplay.Connect~~~~0.0.1.0
      3. Sets all active connected network profiles to Private so mDNS/Miracast discovery is not blocked.
      4. Registers Windows Defender Firewall inbound allow rules for ComSSUCast.exe,
         ComSSUMiracastHelper.exe, TCP 7250, TCP 7236, UDP 1028, UDP 5353, UDP 1900,
         TCP 8009, AirPlay/RTP ports (TCP 7000-7001,7100 / UDP 6000-6001,7010-7011),
         and ComSSU Cast Companion/Web UI ports (TCP 7400, 7401).

.PARAMETER AppDirectory
    Optional path to the directory containing ComSSUCast.exe and ComSSUMiracastHelper.exe.
    Defaults to the directory where this script is located (or the parent repository/build directory).
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$AppDirectory = ""
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " ComSSU Cast — Windows Miracast & Discovery Setup" -ForegroundColor Cyan
Write-Host " Receiver Name: CS Society Display" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# 0. Verify Administrator Privileges
# ---------------------------------------------------------------------------
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "This script must be run as Administrator to configure DISM features, network profiles, and Windows Firewall."
    Write-Host "Right-click PowerShell -> 'Run as Administrator', then run:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -ForegroundColor Yellow
    exit 1
}

# ---------------------------------------------------------------------------
# 1. Check Wi-Fi Driver & Graphics Driver Miracast Support
# ---------------------------------------------------------------------------
Write-Host "[1/4] Checking Wi-Fi Direct & Miracast driver support..." -ForegroundColor Green

try {
    $wlanOutput = (netsh wlan show drivers 2>&1) | Out-String
    $wirelessDisplayLine = ($wlanOutput -split "`r?`n") | Where-Object { $_ -match "Wireless Display Supported" }
    if ($wirelessDisplayLine) {
        Write-Host "  $($wirelessDisplayLine.Trim())"
    } else {
        Write-Warning "  Could not find 'Wireless Display Supported' in 'netsh wlan show drivers'. Ensure Wi-Fi is enabled."
    }
} catch {
    Write-Warning "  Could not query WLAN driver info: $($_.Exception.Message)"
}

try {
    [void][Windows.Media.Miracast.MiracastReceiver, Windows.Media.Miracast, ContentType=WindowsRuntime]
    $receiver = New-Object Windows.Media.Miracast.MiracastReceiver
    $status = $receiver.GetStatus()
    Write-Host "  WinRT MiracastReceiver WiFiStatus:      $($status.WiFiStatus)"
    Write-Host "  WinRT MiracastReceiver ListeningStatus: $($status.ListeningStatus)"
} catch {
    Write-Warning "  WinRT MiracastReceiver check returned: $($_.Exception.Message)"
}
Write-Host ""

# ---------------------------------------------------------------------------
# 2. Check & Install Windows Wireless Display Optional Feature
# ---------------------------------------------------------------------------
Write-Host "[2/4] Checking Windows 'Wireless Display' capability (App.WirelessDisplay.Connect)..." -ForegroundColor Green

$capName = "App.WirelessDisplay.Connect~~~~0.0.1.0"
$capInfo = Get-WindowsCapability -Online -Name $capName -ErrorAction SilentlyContinue

if ($null -ne $capInfo -and $capInfo.State -eq "Installed") {
    Write-Host "  Wireless Display capability ($capName) is already Installed." -ForegroundColor Gray
} else {
    Write-Host "  Installing Wireless Display capability via DISM (requires internet/Windows Update)..." -ForegroundColor Yellow
    & DISM.exe /Online /Add-Capability /CapabilityName:$capName
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "  DISM returned exit code $LASTEXITCODE. If Windows Update is metered or offline, ensure internet access and retry."
    } else {
        Write-Host "  Wireless Display capability installed successfully." -ForegroundColor Green
    }
}
Write-Host ""

# ---------------------------------------------------------------------------
# 3. Set Active Network Profile(s) to Private
# ---------------------------------------------------------------------------
Write-Host "[3/4] Setting active network profile(s) to Private for local discovery..." -ForegroundColor Green

try {
    $profiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
    if ($profiles) {
        foreach ($prof in $profiles) {
            if ($prof.NetworkCategory -ne "Private" -and $prof.NetworkCategory -ne "DomainAuthenticated") {
                Set-NetConnectionProfile -InterfaceIndex $prof.InterfaceIndex -NetworkCategory Private
                Write-Host "  Updated network '$($prof.Name)' (InterfaceIndex $($prof.InterfaceIndex)) -> Private"
            } else {
                Write-Host "  Network '$($prof.Name)' is already $($prof.NetworkCategory)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Warning "  No active network connection profiles found."
    }
} catch {
    Write-Warning "  Failed to update network profile: $($_.Exception.Message)"
}
Write-Host ""

# ---------------------------------------------------------------------------
# 4. Add Windows Defender Firewall Inbound Rules
# ---------------------------------------------------------------------------
Write-Host "[4/4] Configuring Windows Defender Firewall rules for ComSSU Cast..." -ForegroundColor Green

# Resolve application directory containing ComSSUCast.exe and ComSSUMiracastHelper.exe
$searchDirs = @()
if (-not [string]::IsNullOrWhiteSpace($AppDirectory)) {
    $searchDirs += $AppDirectory
}
$searchDirs += @(
    $PSScriptRoot,
    (Split-Path -Parent $PSScriptRoot),
    (Join-Path (Split-Path -Parent $PSScriptRoot) "dist\ComSSUCast"),
    (Join-Path (Split-Path -Parent $PSScriptRoot) "build"),
    (Join-Path (Split-Path -Parent $PSScriptRoot) "build\Release"),
    (Join-Path (Split-Path -Parent $PSScriptRoot) "build\Debug"),
    (Join-Path (Split-Path -Parent $PSScriptRoot) "build\windows-debug"),
    (Join-Path (Split-Path -Parent $PSScriptRoot) "tools\miracast-helper"),
    "$env:ProgramFiles\ComSSUCast",
    "$env:LOCALAPPDATA\Programs\ComSSUCast"
)

function Find-AllBinaryPaths([string]$exeName) {
    $found = New-Object System.Collections.Generic.List[string]
    foreach ($dir in $searchDirs) {
        if ($dir -and (Test-Path (Join-Path $dir $exeName))) {
            $resolved = (Resolve-Path (Join-Path $dir $exeName)).Path
            if (-not $found.Contains($resolved)) {
                $found.Add($resolved)
            }
        }
    }
    return $found
}

$mainExePaths   = Find-AllBinaryPaths "ComSSUCast.exe"
$helperExePaths = Find-AllBinaryPaths "ComSSUMiracastHelper.exe"

# Always include the default Inno Setup install paths in C:\Program Files\ComSSUCast
# even if setup-windows-miracast.ps1 is run before ComSSUCast-windows-x64-Setup.exe is installed.
$defaultInstalledMain   = "$env:ProgramFiles\ComSSUCast\ComSSUCast.exe"
$defaultInstalledHelper = "$env:ProgramFiles\ComSSUCast\ComSSUMiracastHelper.exe"
if (-not $mainExePaths.Contains($defaultInstalledMain)) {
    $mainExePaths.Add($defaultInstalledMain)
}
if (-not $helperExePaths.Contains($defaultInstalledHelper)) {
    $helperExePaths.Add($defaultInstalledHelper)
}

# Remove any stale ComSSUCast firewall rules before re-creating clean ones
Get-NetFirewallRule -DisplayName "ComSSUCast*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue

# Ensure any auto-created Windows Firewall query rules for comssucast cover Private, Domain, and Public
Get-NetFirewallRule -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match "comssucast" } |
    ForEach-Object {
        Set-NetFirewallRule -Name $_.Name -Action Allow -Enabled True -Profile Private,Domain,Public -ErrorAction SilentlyContinue
    }

if ($mainExePaths.Count -gt 0) {
    $idx = 1
    foreach ($exePath in $mainExePaths) {
        New-NetFirewallRule -DisplayName "ComSSUCast Application #$idx (Inbound)" `
            -Direction Inbound -Action Allow -Program $exePath `
            -Profile Private,Domain,Public -Enabled True | Out-Null
        Write-Host "  Allowed executable (all TCP/UDP ports): $exePath"
        $idx++
    }
} else {
    Write-Host "  Note: ComSSUCast.exe not found in default paths (port rules will still be added)." -ForegroundColor Yellow
}

if ($helperExePaths.Count -gt 0) {
    $idx = 1
    foreach ($exePath in $helperExePaths) {
        New-NetFirewallRule -DisplayName "ComSSUCast Miracast Helper #$idx (Inbound)" `
            -Direction Inbound -Action Allow -Program $exePath `
            -Profile Private,Domain,Public -Enabled True | Out-Null
        Write-Host "  Allowed executable (all TCP/UDP ports): $exePath"
        $idx++
    }
} else {
    Write-Host "  Note: ComSSUMiracastHelper.exe not found in default paths (port rules will still be added)." -ForegroundColor Yellow
}

# Allow Windows native Miracast runtime hosts (CastSrv.exe and WUDFHost.exe) across all profiles
# so dynamic RTSP/RTP media ports over the Wi-Fi Direct Virtual Adapter (Public profile) and LAN are never blocked.
$systemMiracastHosts = @(
    @{ Name = "ComSSUCast Windows CastSrv (Inbound)";  Path = "$env:WINDIR\System32\CastSrv.exe" },
    @{ Name = "ComSSUCast Windows WUDFHost (Inbound)"; Path = "$env:WINDIR\System32\WUDFHost.exe" }
)
foreach ($sysHost in $systemMiracastHosts) {
    if (Test-Path $sysHost.Path) {
        New-NetFirewallRule -DisplayName $sysHost.Name `
            -Direction Inbound -Action Allow -Program $sysHost.Path `
            -Profile Private,Domain,Public -Enabled True | Out-Null
        Write-Host "  Allowed Windows Miracast runtime host: $($sysHost.Path)"
    }
}

# Port rules covering Miracast (MS-MICE/RTSP/RTP), mDNS, Google Cast, AirPlay, DLNA/SSDP, and Web UI
$portRules = @(
    @{ Name = "ComSSUCast Miracast MS-MICE (TCP 7250)"; Protocol = "TCP"; Ports = @("7250") },
    @{ Name = "ComSSUCast Miracast RTSP (TCP 7236)";    Protocol = "TCP"; Ports = @("7236") },
    @{ Name = "ComSSUCast Miracast RTP (UDP 1028)";     Protocol = "UDP"; Ports = @("1028") },
    @{ Name = "ComSSUCast mDNS Discovery (UDP 5353)";   Protocol = "UDP"; Ports = @("5353") },
    @{ Name = "ComSSUCast SSDP DLNA (UDP 1900)";        Protocol = "UDP"; Ports = @("1900") },
    @{ Name = "ComSSUCast Google Cast (TCP 8009)";      Protocol = "TCP"; Ports = @("8009") },
    @{ Name = "ComSSUCast AirPlay Control (TCP)";       Protocol = "TCP"; Ports = @("7000-7001", "7100") },
    @{ Name = "ComSSUCast AirPlay RTP (UDP)";           Protocol = "UDP"; Ports = @("6000-6001", "7010-7011") },
    @{ Name = "ComSSUCast Companion & Web UI (TCP)";    Protocol = "TCP"; Ports = @("7400", "7401") }
)

foreach ($rule in $portRules) {
    New-NetFirewallRule -DisplayName $rule.Name `
        -Direction Inbound -Action Allow `
        -Protocol $rule.Protocol -LocalPort $rule.Ports `
        -Profile Private,Domain,Public -Enabled True | Out-Null
    Write-Host "  Allowed $($rule.Protocol) port(s): $($rule.Ports -join ', ') ($($rule.Name))"
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " Setup Complete! 'CS Society Display' is ready to receive:" -ForegroundColor Green
Write-Host "   - Windows 10/11 (Win + K / Cast)" -ForegroundColor White
Write-Host "   - Android (Smart View / Cast / Wireless Display)" -ForegroundColor White
Write-Host "   - Apple iOS / iPadOS / macOS (AirPlay Screen Mirroring)" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan
