# Firmware'i derler: build\etof_demo.elf
param([switch]$Clean)

. $PSScriptRoot\env.ps1

if ($Clean -and (Test-Path $BuildDir)) { Remove-Item -Recurse -Force $BuildDir }

# CMAKE_POLICY_VERSION_MINIMUM: CMake 4.x ile pico-sdk'nin eski alt projeleri için
# (Tırnaklar gerekli: PowerShell 5.1 aksi hâlde "3.5"i noktadan böler.)
cmake -S $ProjectRoot -B $BuildDir -G Ninja '-DPICO_BOARD=pico' '-DCMAKE_BUILD_TYPE=Debug' '-DCMAKE_POLICY_VERSION_MINIMUM=3.5'
if ($LASTEXITCODE -ne 0) { throw 'CMake yapilandirmasi basarisiz' }

cmake --build $BuildDir
if ($LASTEXITCODE -ne 0) { throw 'Derleme basarisiz' }

Write-Host "OK: $Firmware"
