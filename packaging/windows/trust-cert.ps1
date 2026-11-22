<#
.SYNOPSIS
    Installs the ComSSU Cast self-signed public certificate into Windows trust stores
    so Windows UAC and Explorer show the verified publisher instead of "Unknown publisher".

.DESCRIPTION
    Run once per Windows machine (as Administrator for system-wide LocalMachine trust,
    which is required for UAC elevation prompts).
#>
[CmdletBinding()]
param(
    [string]$CertPath = (Join-Path $PSScriptRoot "ComSSUCast-Publisher.cer"),
    [ValidateSet("Auto", "LocalMachine", "CurrentUser")]
    [string]$Scope = "Auto"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CertPath)) {
    throw "Public certificate not found at '$CertPath'. Generate it first with create-self-signed-cert.ps1."
}
$resolvedCert = (Resolve-Path -LiteralPath $CertPath).Path

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($Scope -eq "Auto") {
    $Scope = if ($isAdmin) { "LocalMachine" } else { "CurrentUser" }
}

if ($Scope -eq "LocalMachine" -and -not $isAdmin) {
    throw "LocalMachine trust requires an elevated (Administrator) PowerShell prompt. Re-run as Administrator or pass -Scope CurrentUser."
}

$certObj = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($resolvedCert)
$thumbprint = $certObj.Thumbprint
Write-Host "Certificate Subject:    $($certObj.Subject)"
Write-Host "Certificate Thumbprint: $thumbprint"
Write-Host "Target Store Scope:     $Scope"

foreach ($storeName in @("Root", "TrustedPublisher")) {
    $storePath = "Cert:\$Scope\$storeName"
    $existing = Get-ChildItem -Path $storePath | Where-Object { $_.Thumbprint -eq $thumbprint }
    if ($existing) {
        Write-Host "  Already trusted in $storePath" -ForegroundColor DarkGray
    } else {
        Import-Certificate -FilePath $resolvedCert -CertStoreLocation $storePath | Out-Null
        Write-Host "  Imported into $storePath" -ForegroundColor Green
    }
}

if ($Scope -eq "CurrentUser") {
    Write-Warning "Installed for CurrentUser only. Run as Administrator to trust system-wide (required for UAC elevation dialogs)."
} else {
    Write-Host "Done. ComSSU Cast installers and executables signed with this certificate are now trusted on this PC." -ForegroundColor Green
}
