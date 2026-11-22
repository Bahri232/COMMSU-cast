<#
.SYNOPSIS
    Generates a persistent self-signed Windows Authenticode code-signing certificate
    for ComSSU Cast and exports both the private .pfx (for CI/local signing) and
    the public .cer (for trusting on UniMak / classroom Windows PCs).

.EXAMPLE
    .\packaging\windows\create-self-signed-cert.ps1
#>
[CmdletBinding()]
param(
    [string]$Subject = "CN=Abdul Malik Barrie (ComSSU - UniMak), O=Computer Science Students' Society (ComSSU) - UniMak, L=Makeni, C=SL",
    [string]$FriendlyName = "ComSSU Cast Code Signing",
    [int]$YearsValid = 10,
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\..\certs"),
    [string]$PublicCerPath = (Join-Path $PSScriptRoot "ComSSUCast-Publisher.cer"),
    [SecureString]$Password
)

$ErrorActionPreference = "Stop"

if (-not $Password) {
    $Password = Read-Host -Prompt "Enter a password to protect the private .pfx certificate" -AsSecureString
    $Confirm  = Read-Host -Prompt "Confirm the .pfx password" -AsSecureString

    $bstr1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $bstr2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Confirm)
    try {
        $plain1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr1)
        $plain2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr2)
        if ([string]::IsNullOrEmpty($plain1)) {
            throw "Password cannot be empty."
        }
        if ($plain1 -cne $plain2) {
            throw "Passwords do not match."
        }
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)
    }
}

$null = New-Item -ItemType Directory -Path $OutputDir -Force
$pfxPath = Join-Path (Resolve-Path $OutputDir) "ComSSUCast-CodeSign.pfx"
$b64Path = Join-Path (Resolve-Path $OutputDir) "WINDOWS_CERT_PFX_B64.txt"

Write-Host "Creating self-signed code-signing certificate..." -ForegroundColor Cyan
Write-Host "  Subject: $Subject"
Write-Host "  Valid:   $YearsValid years"

$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject $Subject `
    -FriendlyName $FriendlyName `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -HashAlgorithm SHA256 `
    -KeyLength 4096 `
    -KeyExportPolicy Exportable `
    -NotAfter (Get-Date).AddYears($YearsValid)

try {
    Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $Password | Out-Null
    Export-Certificate -Cert $cert -FilePath $PublicCerPath -Type CERT | Out-Null

    $pfxBytes = [IO.File]::ReadAllBytes($pfxPath)
    [IO.File]::WriteAllText($b64Path, [Convert]::ToBase64String($pfxBytes))
} finally {
    # Remove the exportable private key from CurrentUser\My if you only want it in the PFX file
    # (Leave commented if you also sign directly from the store; uncomment to keep store clean.)
}

Write-Host ""
Write-Host "Certificate created successfully!" -ForegroundColor Green
Write-Host "  Thumbprint:          $($cert.Thumbprint)"
Write-Host "  Private PFX (keep secret, gitignored): $pfxPath"
Write-Host "  Base64 PFX  (keep secret, gitignored): $b64Path"
Write-Host "  Public CER  (safe to commit/share):    $PublicCerPath"
Write-Host ""
Write-Host "Next steps for GitHub Actions signing:" -ForegroundColor Yellow
Write-Host "  1. In GitHub repo Settings -> Secrets and variables -> Actions, add:"
Write-Host "       WINDOWS_CERT_PFX_B64  = contents of $b64Path"
Write-Host "       WINDOWS_CERT_PASSWORD = the password you just entered"
Write-Host "  2. Commit $PublicCerPath (never commit $OutputDir)."
Write-Host "  3. On each target Windows PC (as Administrator), run:"
Write-Host "       powershell -ExecutionPolicy Bypass -File packaging\windows\trust-cert.ps1"
