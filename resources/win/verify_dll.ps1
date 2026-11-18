# Set-PSDebug -Trace 1

$ErrorActionPreference = "Stop"

$unsignedBinaries = Get-ChildItem -Path "." -Recurse -File |
  Where-Object { $_.Extension -in @(".exe", ".dll") } |
  Where-Object { (Get-AuthenticodeSignature $_.FullName).Status -ne 'Valid' } | 
  Select-Object -ExpandProperty FullName

if ($unsignedBinaries) {
    Write-Host "ERROR: Found unsigned executable(s) or DLL(s):"
    $unsignedBinaries | ForEach-Object { Write-Host "  - $_" }
    exit 1
} else {
    Write-Host "SUCCESS: All executables and DLLs are signed."
}