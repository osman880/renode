# Ortak ortam ayarları. Diğer scriptler bunu ". $PSScriptRoot\env.ps1" ile yükler.
# Araçlar başka bir yerdeyse ETOF_TOOLS ortam değişkenini ayarlayın.

# 'Stop' kullanmıyoruz: Windows PowerShell 5.1, cmake/ninja'nın stderr'e yazdığı
# uyarıları hata sayıp scripti durdurur. Hatalar $LASTEXITCODE ile kontrol edilir.
$ErrorActionPreference = 'Continue'

$Tools = if ($env:ETOF_TOOLS) { $env:ETOF_TOOLS } else { Join-Path $env:USERPROFILE 'tools' }
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BuildDir = Join-Path $ProjectRoot 'build'
$Firmware = Join-Path $BuildDir 'etof_demo.elf'

$RenodeExe = Join-Path $Tools 'renode\renode.exe'
$Rp2040Dir = Join-Path $Tools 'Renode_RP2040'
$VenvPython = Join-Path $Tools 'renode-venv\Scripts\python.exe'
$env:PICO_SDK_PATH = Join-Path $Tools 'pico-sdk'
$env:PICO_TOOLCHAIN_PATH = Join-Path $Tools 'arm-gnu-toolchain'

# winget ile kurulan cmake/ninja yeni açılmamış kabuklarda PATH'te olmayabilir
$env:Path = (Join-Path $Tools 'arm-gnu-toolchain\bin') + ';' +
    [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
    [Environment]::GetEnvironmentVariable('Path', 'Machine')

foreach ($p in @($RenodeExe, $Rp2040Dir, $env:PICO_SDK_PATH, $env:PICO_TOOLCHAIN_PATH)) {
    if (-not (Test-Path $p)) { throw "Bulunamadi: $p (once scripts\setup-tools.ps1 calistirin)" }
}

# Renode komutlarında ters eğik çizgi yerine düz eğik çizgi kullanılır
function ConvertTo-RenodePath([string]$Path) { '@' + ($Path -replace '\\', '/') }
