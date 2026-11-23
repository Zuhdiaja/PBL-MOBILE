$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath "$PSScriptRoot/.local-env.ps1") {
    . "$PSScriptRoot/.local-env.ps1"
}
Push-Location $PSScriptRoot
try {
    & "$PSScriptRoot/.venv/Scripts/python.exe" push_worker.py
} finally {
    Pop-Location
}
