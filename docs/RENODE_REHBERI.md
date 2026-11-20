# Renode Rehberi (ETOF projesi için)

## Renode nedir, neden kullanıyoruz?

Renode, Antmicro'nun açık kaynak tam-sistem simülatörüdür. Derlenmiş firmware'i (aynı `.elf`) CPU, bellek ve çevre birimi modelleri üzerinde çalıştırır. Bu projede üç işe yarar:

1. **Donanımsız geliştirme:** Pico gelmeden sürücü ve scheduler mantığı yazılıp denenebilir.
2. **Tekrarlanabilir test:** Robot Framework testleri her değişiklikte aynı sonucu verir. Bu, DO-178C'deki "doğrulama kanıtı" anlayışının küçük ölçekli bir karşılığıdır.
3. **Görünürlük:** Register erişimleri, kesmeler ve bellek okunup yazılabilir; donanımda bunlar zor gözlenir.

## Temel kavramlar

| Kavram | Dosya | Anlamı |
|---|---|---|
| Platform (`.repl`) | `Renode_RP2040/cores/rp2040.repl` | Donanımın tarifi: hangi CPU, hangi adreste hangi çevre birimi, kesme hatları |
| Script (`.resc`) | `sim/pico.resc` | Monitör komutlarından oluşan kurulum senaryosu |
| Monitör | Renode konsolu | Simülasyonu yöneten komut satırı |
| Analyzer | `showAnalyzer sysbus.uart0` | UART çıktısını gösteren pencere |
| Robot testi | `tests/smoke.robot` | Otomatik senaryo: "şu satır UART'ta görünmeli" |

## Sık kullanılan monitör komutları

`scripts\sim.ps1` ile açılan pencerede:

```
start                                  # simülasyonu başlat
pause                                  # duraklat
emulation RunFor "00:00:01"            # 1 sanal saniye çalıştır ve dur
sysbus.cpu0 PC                         # program sayacı
sysbus.cpu0 Step 10                    # 10 komut adım adım
sysbus ReadDoubleWord 0xE000ED90       # bellek/register oku (burada MPU_TYPE)
sysbus WriteDoubleWord 0xd0000014 0x2000000   # register yaz
sysbus LogPeripheralAccess sysbus.uart0 true  # UART'a her erişimi logla
sysbus.cpu0 LogFunctionNames true      # çağrılan fonksiyonları logla (yoğun!)
logLevel -1 sysbus.uart0               # tek çevre birimi için ayrıntılı log
machine StartGdbServer 3333            # arm-none-eabi-gdb ile bağlanmak için
peripherals                            # tüm çevre birimleri ve adresleri
quit
```

GDB ile hata ayıklama:

```powershell
& "$env:USERPROFILE\tools\arm-gnu-toolchain\bin\arm-none-eabi-gdb.exe" build\etof_demo.elf -ex "target remote :3333"
```

## Bu projede faz faz Renode kullanımı

| Faz | Renode'da yapılacak | Donanımda yapılacak |
|---|---|---|
| F1 | Mimari prototip, schedule tablosu doğrulama testleri | – |
| F2 | Sürücü register mantığı, kesme akışı, `LogPeripheralAccess` ile doğrulama | Sinyal seviyeleri, gerçek sensörler |
| F3 | Scheduler ve APEX testleri; her servis için Robot testi | – |
| F4 | MPU ihlali → fault → Health Monitor akışı (model destekliyorsa) | Gerçek izolasyon ve çift çekirdek davranışı |
| F5 | Regresyon seti (tüm testler yeşil kalmalı) | **Tüm zamanlama ölçümleri** |

## İlk alıştırmalar (sanayi danışmanı ve öğrenciler için)

1. `src/main.c` içinde P3'ün penceresini `{ 2, 80, 30 }` yapın ve derleyin. `schedule_validate` hatayı yakalamalı ve UART'ta `CONFIG ERROR` görünmeli.
2. `p2_comm` içine 50 ms'lik bir `busy_wait_ms(50)` ekleyin. `HM: deadline miss in P2_COMM` görünmeli ve `Deadline Miss Olmamali` testi kırmızıya dönmeli. Ardından şunu tartışın: Kooperatif modelde P3'ün penceresi neden kayıyor? Preemption neden gerekli?
3. Monitörde `sysbus LogPeripheralAccess sysbus.gpio true` açıp LED (GPIO25) toggle'ını register seviyesinde izleyin.
4. **T2 MPU prototipi:** Bir MPU bölgesini salt-okunur yapıp yazmaya çalışan küçük bir test yazın. Renode'da fault oluşuyor mu? Sonuç, F4 planını belirler.

## Kaynaklar

- Renode dokümantasyonu: https://renode.readthedocs.io
- Renode_RP2040 modeli: https://github.com/matgla/Renode_RP2040
- RP2040 datasheet: https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf
- pico-sdk: https://github.com/raspberrypi/pico-sdk
