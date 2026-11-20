# Robot Framework testlerini Renode üzerinde koşar. Sonuçlar: build\test-results
param([string]$Suite = 'tests\smoke.robot')

. $PSScriptRoot\env.ps1
if (-not (Test-Path $Firmware)) { throw "Firmware yok: $Firmware. Once scripts\build.ps1 calistirin." }

$renodeTests = Join-Path $Tools 'renode\tests'
$results = Join-Path $BuildDir 'test-results'
New-Item -ItemType Directory -Force $results | Out-Null

# Robot Framework 6.1 "utf-8:surrogateescape" gibi değerleri tanımıyor
$env:PYTHONIOENCODING = 'utf-8'

& $VenvPython (Join-Path $renodeTests 'run_tests.py') `
    --css-file (Join-Path $renodeTests 'robot.css') `
    --exclude skip_windows `
    --robot-framework-remote-server-full-directory (Join-Path $Tools 'renode') `
    -r $results `
    --variable "FIRMWARE:$($Firmware -replace '\\','/')" `
    --variable "RP2040:$($Rp2040Dir -replace '\\','/')" `
    --variable "PROJECT:$($ProjectRoot -replace '\\','/')" `
    (Join-Path $ProjectRoot $Suite)

exit $LASTEXITCODE
