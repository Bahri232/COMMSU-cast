# tools/miracast-helper/build-helper.ps1
# Compiles ComSSUMiracastHelper.cs into ComSSUMiracastHelper.exe using Windows' built-in
# .NET Framework 4.x C# compiler (csc.exe) and Windows Runtime metadata (WinMD).

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path $PSScriptRoot "ComSSUMiracastHelper.exe")
)

$ErrorActionPreference = "Stop"

$sourceFile = Join-Path $PSScriptRoot "ComSSUMiracastHelper.cs"
if (-not (Test-Path $sourceFile)) {
    throw "Source file not found: $sourceFile"
}

$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$fwDir = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319"
$csc = Join-Path $fwDir "csc.exe"
if (-not (Test-Path $csc)) {
    throw "Windows built-in C# compiler not found at: $csc"
}

$winmdDir = "$env:WINDIR\System32\WinMetadata"
$refs = @(
    (Join-Path $fwDir "System.Runtime.WindowsRuntime.dll"),
    (Join-Path $fwDir "System.Runtime.dll"),
    (Join-Path $fwDir "System.Runtime.InteropServices.WindowsRuntime.dll"),
    (Join-Path $fwDir "System.Numerics.dll"),
    (Join-Path $fwDir "System.Numerics.Vectors.dll"),
    (Join-Path $fwDir "System.Windows.Forms.dll"),
    (Join-Path $fwDir "System.Drawing.dll"),
    (Join-Path $winmdDir "Windows.Foundation.winmd"),
    (Join-Path $winmdDir "Windows.Media.winmd"),
    (Join-Path $winmdDir "Windows.UI.winmd"),
    (Join-Path $winmdDir "Windows.ApplicationModel.winmd")
)

$refArgs = @()
foreach ($r in $refs) {
    if (-not (Test-Path $r)) {
        throw "Required WinRT/Framework reference not found: $r"
    }
    $refArgs += "/r:$r"
}

& $csc /nologo /optimize+ /platform:x64 /target:exe "/out:$OutputPath" @refArgs $sourceFile
if ($LASTEXITCODE -ne 0) {
    throw "csc.exe failed with exit code $LASTEXITCODE"
}

Write-Host "Built ComSSUMiracastHelper.exe -> $OutputPath"
