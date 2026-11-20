# ETOF – RTOS üzerinde ARINC653 Prensipleri ile Aviyonik Sürücü Geliştirme

LIFT UP Sanayi Odaklı Lisans Bitirme Projesi (#3F9ADDDA1F4D). Hedef donanım: Raspberry Pi Pico (RP2040).
Bu depo, donanım olmadan **Renode** simülatöründe geliştirme ve otomatik test yapmak için hazırlanmış bir başlangıç iskeletidir.

## Hızlı başlangıç (Windows, PowerShell)

```powershell
# 1) Araçları kur (ilk seferde ~400 MB indirir, yönetici yetkisi gerekmez)
.\scripts\setup-tools.ps1

# 2) Firmware'i derle  ->  build\etof_demo.elf
.\scripts\build.ps1

# 3) Otomatik testleri koş (Renode + Robot Framework, ~1.5 dk)
.\scripts\test.ps1          # rapor: build\test-results\report.html

# 4) Simülasyonu etkileşimli aç (UART penceresi + Renode monitörü)
.\scripts\sim.ps1
```

İlk açılışta Renode, RP2040 çevre birimlerini kaynak koddan derlediği için 30–60 saniye bekler. Bu normaldir.

## Demo ne yapıyor?

`src/main.c`, 100 ms'lik statik bir **major frame** tanımlar ve üç partition'ı sırayla kendi zaman pencerelerinde çalıştırır:

```
0 ms          40 ms         80 ms     100 ms
|   P1_NAV    |   P2_COMM   |  P3_HM  |   ← her major frame'de tekrar
```

UART çıktısı:

```
ETOF ARINC653 demo baslatildi
Schedule OK: 3 partition, major frame 100 ms
[    4400 us] frame 0 window 0 -> P1_NAV
[   44400 us] frame 0 window 1 -> P2_COMM
[   84400 us] frame 0 window 2 -> P3_HM
P3_HM: alive, comm_counter=1
...
```

Bu bir **iskelet**tir: Kooperatif bir döngüsel yürütücüdür (cyclic executive). Gerçek bölütleme henüz yok; bunlar projenin kendisidir:

| Eksik | Hangi fazda |
|---|---|
| Register seviyesinde GPIO/UART/I2C/SPI sürücüleri, kesme, DMA | F2 |
| Timer kesmesiyle preemption (pencere sonunda partition'ı zorla durdurma) | F3 |
| APEX servisleri, sampling/queuing port'lar | F3 |
| MPU ile mekansal izolasyon, ayrıcalıksız mod | F4 |
| Çift çekirdek, Health Monitor kurtarma aksiyonları | F4 |

## Dizin yapısı

```
CMakeLists.txt         pico-sdk tabanlı derleme
src/                   firmware kaynakları
  schedule.[ch]        major frame tablosu, doğrulama, çevrim
  main.c               3 partition'lı demo
sim/
  pico.resc            Renode platform + firmware yükleme
  headless.resc        GUI'siz koşu, UART'ı dosyaya yazar
tests/
  smoke.robot          Robot Framework testleri (Renode keyword'leri)
scripts/
  setup-tools.ps1      araç kurulumu
  build.ps1            derleme (-Clean ile temiz derleme)
  test.ps1             testler
  sim.ps1              etkileşimli simülasyon
docs/
  RENODE_REHBERI.md    Renode'a giriş ve proje için kullanım notları
```

## Araç sürümleri

Sürümler birbirine bağlı olduğu için sabitlendi. Güncellerken birlikte test edin.

| Araç | Sürüm | Not |
|---|---|---|
| Renode | 1.16.1 (portable, .NET) | Renode_RP2040 bu sürümü şart koşuyor |
| [Renode_RP2040](https://github.com/matgla/Renode_RP2040) | `5aca847` | Topluluk modeli, MIT. README'sine göre WIP ve "frozen" |
| pico-sdk | 2.1.0 | Renode_RP2040 testleri bu sürümle yapılmış |
| Arm GNU Toolchain | 14.2.Rel1 | |
| CMake / Ninja | 4.x / 1.13 | winget |

## Simülasyonun sınırları (önemli)

- **Zamanlama döngü hassasiyetinde değildir.** Renode sanal zamanla ve komut blokları hâlinde çalışır. Jitter, kesme gecikmesi ve frame sapması ölçümleri (F5) **gerçek Pico ve lojik analizörle** yapılmalıdır. Simülatördeki zaman damgaları yalnızca mantıksal sırayı doğrular.
- **MPU:** Simüle edilen Cortex-M0+ çekirdeği 8 bölgeli MPU bildiriyor (`MPU_TYPE = 0x800`). Ancak ihlal anında MemManage/HardFault üretip üretmediği **henüz doğrulanmadı**. Bu, T2 (04.12.2026) için planlanan prototipin konusu.
- Modelde **PWM, USB ve RTC yok**. SPI yalnızca master modda çalışıyor. Bazı çevre birimleri kısmi (ayrıntı: Renode_RP2040 README).
- Simülasyonda geçen her test, donanımda da doğrulanmalıdır.

## Gerçek donanıma yükleme

Şu an yalnızca `.elf` üretiliyor. UF2 için `CMakeLists.txt` içine `pico_add_extra_outputs(etof_demo)` eklenmeli (pico-sdk 2.x bunun için picotool ister). Alternatif olarak SWD/debug probe ile `.elf` doğrudan yüklenebilir.
