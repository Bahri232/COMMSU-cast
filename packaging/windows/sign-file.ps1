<#
.SYNOPSIS
    Signs a Windows binary (.exe / .dll) with an Authenticode PFX certificate.
    Used by CI and Inno Setup SignTool.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$FilePath,

    [string]$PfxPath = $env:SIGN_PFX_PATH,
    [string]$PfxPassword = $env:SIGN_PFX_PASSWORD,
    [string]$TimestampUrl = "http://timestamp.digicert.com",
    [string]$Description = "ComSSU Wireless Display System",
    [string]$DescriptionUrl = "https://unimak.edu.sl"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $FilePath)) {
    throw "Target file not found: $FilePath"
}
$resolvedFile = (Resolve-Path -LiteralPath $FilePath).Path

if ([string]::IsNullOrWhiteSpace($PfxPath) -or -not (Test-Path -LiteralPath $PfxPath)) {
    throw "PFX certificate not found. Set SIGN_PFX_PATH or pass -PfxPath."
}
$resolvedPfx = (Resolve-Path -LiteralPath $PfxPath).Path

if ([string]::IsNullOrEmpty($PfxPassword)) {
    throw "PFX password is empty. Set SIGN_PFX_PASSWORD or pass -PfxPassword."
}

function Find-SignTool {
    $cmd = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $kitsRoot = "${env:ProgramFiles(x86)}\Windows Kits\10\bin"
    if (Test-Path $kitsRoot) {
        $candidate = Get-ChildItem -Path $kitsRoot -Recurse -Filter "signtool.exe" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($candidate) { return $candidate.FullName }
    }
    return $null
}

$signtool = Find-SignTool

if ($signtool) {
    Write-Host "Signing '$resolvedFile' with signtool.exe..."
    & $signtool sign /f $resolvedPfx /p $PfxPassword /fd SHA256 /d $Description /du $DescriptionUrl /tr $TimestampUrl /td SHA256 $resolvedFile
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Timestamped signing failed (exit $LASTEXITCODE); retrying without timestamp server..."
        & $signtool sign /f $resolvedPfx /p $PfxPassword /fd SHA256 /d $Description /du $DescriptionUrl $resolvedFile
        if ($LASTEXITCODE -ne 0) {
            throw "signtool.exe failed with exit code $LASTEXITCODE"
        }
    }
    exit 0
}

Write-Host "signtool.exe not found; signing '$resolvedFile' with Set-AuthenticodeSignature..."
$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($resolvedPfx, $PfxPassword)
try {
    $sig = Set-AuthenticodeSignature -FilePath $resolvedFile -Certificate $cert -HashAlgorithm SHA256 -TimestampServer $TimestampUrl
    if ($sig.Status -in @('NotSigned', 'HashMismatch', 'Incompatible')) {
        Write-Warning "Timestamped Set-AuthenticodeSignature returned '$($sig.Status)'; retrying without timestamp..."
        $sig = Set-AuthenticodeSignature -FilePath $resolvedFile -Certificate $cert -HashAlgorithm SHA256
    }
    if (-not $sig.SignerCertificate -or $sig.Status -in @('NotSigned', 'HashMismatch', 'Incompatible')) {
        throw "Set-AuthenticodeSignature failed: $($sig.Status) - $($sig.StatusMessage)"
    }
} finally {
    $cert.Dispose()
}
