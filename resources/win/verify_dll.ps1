# Set-PSDebug -Trace 1

$ErrorActionPreference = "Stop"

$unsignedDlls = Get-ChildItem -Path "." -Recurse -Filter *.dll | 
  Where-Object { (Get-AuthenticodeSignature $_.FullName).Status -ne 'Valid' } | 
  Select-Object -ExpandProperty FullName

if ($unsignedDlls) {
    Write-Host "ERROR: Found unsigned DLL(s):"
    $unsignedDlls | ForEach-Object { Write-Host "  - $_" }
    exit 1
} else {
    Write-Host "SUCCESS: All DLLs are signed."
}