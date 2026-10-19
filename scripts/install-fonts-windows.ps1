# Install only this skill's four bundled font faces for the current Windows user.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
$fontSource = Join-Path $skillRoot 'fonts\Libre_Franklin\static'
$fontDestination = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$fontRegistry = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
$faces = [ordered]@{
    Regular = 'Libre Franklin (TrueType)'
    Bold = 'Libre Franklin Bold (TrueType)'
    Italic = 'Libre Franklin Italic (TrueType)'
    BoldItalic = 'Libre Franklin Bold Italic (TrueType)'
}

# Validate the whole operation before copying or registering any face.
foreach ($face in $faces.Keys) {
    $source = Join-Path $fontSource "LibreFranklin-$face.ttf"
    $destination = Join-Path $fontDestination "LibreFranklin-$face.ttf"
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Missing bundled font: $source" }
    if ((Test-Path -LiteralPath $destination) -and
        (Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
        throw "A different version already exists: $destination. Resolve it before installing."
    }
    $registration = Get-ItemProperty -LiteralPath $fontRegistry -ErrorAction SilentlyContinue
    $existing = if ($registration) { $registration.PSObject.Properties[$faces[$face]].Value } else { $null }
    if ($existing -and $existing -ne $destination) {
        throw "An existing registration points elsewhere: $existing. Resolve it before installing."
    }
}

if (-not ('AcademicPlotsFontRegistration' -as [type])) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class AcademicPlotsFontRegistration {
    [DllImport("gdi32.dll", CharSet=CharSet.Unicode)]
    public static extern int AddFontResourceEx(string path, uint flags, IntPtr reserved);
}
'@
}
New-Item -ItemType Directory -Force -Path $fontDestination | Out-Null
if (-not (Test-Path -LiteralPath $fontRegistry)) {
    New-Item -Path $fontRegistry | Out-Null
}
foreach ($face in $faces.Keys) {
    $source = Join-Path $fontSource "LibreFranklin-$face.ttf"
    $destination = Join-Path $fontDestination "LibreFranklin-$face.ttf"
    if (-not (Test-Path -LiteralPath $destination)) {
        Copy-Item -LiteralPath $source -Destination $destination
    }
    if ([AcademicPlotsFontRegistration]::AddFontResourceEx($destination, 0, [IntPtr]::Zero) -eq 0) {
        throw "Windows could not load $destination"
    }
    New-ItemProperty -LiteralPath $fontRegistry -Name $faces[$face] -Value $destination -PropertyType String -Force | Out-Null
    Write-Output "Registered Libre Franklin $face for the current user."
}
Copy-Item -LiteralPath (Join-Path $skillRoot 'fonts\Libre_Franklin\OFL.txt') -Destination (Join-Path $fontDestination 'LibreFranklin-OFL.txt') -Force
Write-Output 'Start a fresh R process before exporting. Verify the PDF with pdffonts; R font discovery alone does not check embedding.'
