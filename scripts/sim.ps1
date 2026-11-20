# Firmware'i Renode'da etkileşimli olarak açar (UART penceresi + Renode monitörü).
# Monitörde: start, pause, quit ... (docs/RENODE_REHBERI.md)
param([string]$Elf)

. $PSScriptRoot\env.ps1
if (-not $Elf) { $Elf = $Firmware }
if (-not (Test-Path $Elf)) { throw "Firmware yok: $Elf. Once scripts\build.ps1 calistirin." }

$resc = ConvertTo-RenodePath (Join-Path $ProjectRoot 'sim\pico.resc')
$cmds = "`$rp2040=$(ConvertTo-RenodePath $Rp2040Dir); `$firmware=$(ConvertTo-RenodePath $Elf); include $resc; showAnalyzer sysbus.uart0; start"

& $RenodeExe -e $cmds
