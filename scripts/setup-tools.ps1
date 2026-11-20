# Geliştirme araçlarını %USERPROFILE%\tools altına kurar (yönetici yetkisi gerekmez).
# Zaten kurulu olanları atlar; tekrar çalıştırmak güvenlidir.
#
#   Renode 1.16.1 (portable)        - RP2040 modeli bu sürüme bağlı
#   Renode_RP2040 (sabit commit)    - matgla/Renode_RP2040, MIT
#   Arm GNU Toolchain 14.2.Rel1
#   pico-sdk 2.1.0
#   CMake + Ninja (winget)
#   Robot Framework (Python venv)   - otomatik testler için
#
# Gereksinimler: git, Python 3, winget

$ErrorActionPreference = 'Continue'
$Tools = if ($env:ETOF_TOOLS) { $env:ETOF_TOOLS } else { Join-Path $env:USERPROFILE 'tools' }
New-Item -ItemType Directory -Force $Tools | Out-Null

$RenodeVersion = '1.16.1'
$ArmVersion    = '14.2.rel1'
$PicoSdkTag    = '2.1.0'
$Rp2040Commit  = '5aca847c9f57ed96603e55d28e8ceeefa09e55f6'

function Get-Zip([string]$Url, [string]$Dest) {
    $tmp = Join-Path $Tools ('dl-' + [IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory $tmp | Out-Null
    $zip = Join-Path $tmp 'pkg.zip'
    Write-Host "  indiriliyor: $Url"
    curl.exe -sSL -o $zip $Url
    if ($LASTEXITCODE -ne 0) { throw "Indirme basarisiz: $Url" }
    Expand-Archive -Path $zip -DestinationPath (Join-Path $tmp 'x') -Force
    # Arşivin tek bir üst klasörü varsa onu, yoksa içeriği taşı
    $items = @(Get-ChildItem (Join-Path $tmp 'x'))
    $src = if ($items.Count -eq 1 -and $items[0].PSIsContainer) { $items[0].FullName } else { Join-Path $tmp 'x' }
    Move-Item $src $Dest
    Remove-Item -Recurse -Force $tmp
}

Write-Host '[1/6] CMake ve Ninja'
winget install --id Kitware.CMake -e --scope user --silent --accept-package-agreements --accept-source-agreements --source winget | Out-Null
winget install --id Ninja-build.Ninja -e --silent --accept-package-agreements --source winget | Out-Null

Write-Host "[2/6] Renode $RenodeVersion"
if (-not (Test-Path "$Tools\renode\renode.exe")) {
    Get-Zip "https://github.com/renode/renode/releases/download/v$RenodeVersion/renode-$RenodeVersion.windows-portable-dotnet.zip" "$Tools\renode"
} else { Write-Host '  zaten kurulu' }

Write-Host '[3/6] Renode_RP2040 modeli'
if (-not (Test-Path "$Tools\Renode_RP2040")) {
    git clone https://github.com/matgla/Renode_RP2040.git "$Tools\Renode_RP2040"
    git -C "$Tools\Renode_RP2040" checkout -q $Rp2040Commit
} else { Write-Host '  zaten kurulu' }

Write-Host "[4/6] Arm GNU Toolchain $ArmVersion"
if (-not (Test-Path "$Tools\arm-gnu-toolchain\bin\arm-none-eabi-gcc.exe")) {
    Get-Zip "https://developer.arm.com/-/media/Files/downloads/gnu/$ArmVersion/binrel/arm-gnu-toolchain-$ArmVersion-mingw-w64-x86_64-arm-none-eabi.zip" "$Tools\arm-gnu-toolchain"
} else { Write-Host '  zaten kurulu' }

Write-Host "[5/6] pico-sdk $PicoSdkTag"
if (-not (Test-Path "$Tools\pico-sdk")) {
    git clone --depth 1 -b $PicoSdkTag https://github.com/raspberrypi/pico-sdk.git "$Tools\pico-sdk"
} else { Write-Host '  zaten kurulu' }

Write-Host '[6/6] Robot Framework (venv)'
if (-not (Test-Path "$Tools\renode-venv\Scripts\python.exe")) {
    python -m venv "$Tools\renode-venv"
    & "$Tools\renode-venv\Scripts\python.exe" -m pip install -q -r "$Tools\renode\tests\requirements.txt"
} else { Write-Host '  zaten kurulu' }

Write-Host "Tamam. Araclar: $Tools"
Write-Host 'Siradaki adim: scripts\build.ps1, sonra scripts\test.ps1'
exit 0  # winget "zaten kurulu" durumunda sıfır olmayan kod döndürür
