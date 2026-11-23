<#
.SYNOPSIS
Ships the Visual C++ runtime with the app instead of requiring the
Visual C++ Redistributable to be installed.

.DESCRIPTION
-Bundle copies the Visual C++ runtime DLLs imported by the binaries in the
Flutter app bundle (authenticator.exe, flutter_windows.dll and plugin DLLs)
next to them, from the Visual Studio redistributable directory.

-Verify checks every executable and DLL in the build artifact, failing if a
Visual C++ runtime DLL is imported but not present next to the importing
binary. The Rust binaries (authenticator-helper.exe, ykman-svc.exe) link the
runtime statically and therefore must not import it at all.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ParameterSetName = 'Bundle')]
    [string]$Bundle,
    [Parameter(Mandatory, ParameterSetName = 'Bundle')]
    [ValidateSet('x64', 'arm64')]
    [string]$Arch,
    [Parameter(Mandatory, ParameterSetName = 'Verify')]
    [string]$Verify
)

$ErrorActionPreference = 'Stop'

# DLLs provided by the Visual C++ Redistributable. The Universal CRT
# (api-ms-win-crt-*.dll, ucrtbase.dll) is part of Windows 10 and later.
$crtPattern = '^(vcruntime|msvcp|concrt|vccorlib|vcomp|vcamp)\d+.*\.dll$'

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'Visual Studio with the Visual C++ build tools not found' }

# x64 tools also run on ARM64 hosts, through emulation.
$dumpbin = Get-Item "$vs\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe" -ErrorAction SilentlyContinue |
    Sort-Object { [version]$_.Directory.Parent.Parent.Parent.Name } -Descending |
    Select-Object -First 1
if (-not $dumpbin) { throw 'dumpbin.exe not found' }

function Get-CrtImports([System.IO.FileInfo]$binary) {
    $output = & $dumpbin.FullName /nologo /dependents $binary.FullName
    if ($LASTEXITCODE -ne 0) { throw "dumpbin failed for $($binary.FullName)" }
    @($output | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ -match $crtPattern })
}

function Get-Binaries([string]$directory, [switch]$Recurse) {
    @(Get-ChildItem $directory -File -Recurse:$Recurse | Where-Object { $_.Extension -in '.exe', '.dll' })
}

if ($PSCmdlet.ParameterSetName -eq 'Bundle') {
    $crtDir = Get-Item "$vs\VC\Redist\MSVC\*\$Arch\Microsoft.VC14*.CRT" -ErrorAction SilentlyContinue |
        Sort-Object { [version]$_.Parent.Parent.Name } -Descending |
        Select-Object -First 1
    if (-not $crtDir) { throw "Visual C++ $Arch runtime redistributable not found in $vs" }

    $binaries = Get-Binaries $Bundle
    if ($binaries.Count -eq 0) { throw "No executables or DLLs in $Bundle" }
    $needed = @($binaries | ForEach-Object { Get-CrtImports $_ } | Sort-Object -Unique)
    if ($needed.Count -eq 0) { throw "Nothing in $Bundle imports the Visual C++ runtime; check the pattern" }

    # The runtime DLLs depend on each other, so include their imports as well.
    $pending = [System.Collections.Generic.Queue[string]]::new([string[]]$needed)
    $bundled = @{}
    while ($pending.Count -gt 0) {
        $name = $pending.Dequeue()
        if ($bundled.ContainsKey($name)) { continue }
        $source = Get-Item (Join-Path $crtDir.FullName $name) -ErrorAction SilentlyContinue
        if (-not $source) { throw "$name is not part of the Visual C++ runtime in $($crtDir.FullName)" }
        $bundled[$name] = $source
        Get-CrtImports $source | ForEach-Object { $pending.Enqueue($_) }
    }
    foreach ($source in $bundled.Values | Sort-Object Name) {
        $version = [Diagnostics.FileVersionInfo]::GetVersionInfo($source.FullName).FileVersion
        Write-Host "Bundling $($source.Name) $version"
        Copy-Item $source.FullName $Bundle
    }
} else {
    $binaries = Get-Binaries $Verify -Recurse
    if ($binaries.Count -eq 0) { throw "No executables or DLLs in $Verify" }
    $missing = foreach ($binary in $binaries) {
        foreach ($import in Get-CrtImports $binary) {
            if (-not (Test-Path (Join-Path $binary.DirectoryName $import))) {
                "$($binary.FullName) imports $import"
            }
        }
    }
    if ($missing) {
        throw "Visual C++ runtime DLLs missing from the build artifact:`n" + ($missing -join "`n")
    }
    Write-Host "All Visual C++ runtime dependencies are satisfied within the build artifact"
}
