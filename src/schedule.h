/*
 * ARINC653 tarzı statik zaman çizelgesi (major/minor frame) iskeleti.
 *
 * Bu dosya bir BAŞLANGIÇ NOKTASIDIR: gerçek bölütleme (MPU ile mekansal
 * izolasyon, kesmeyle preemption) henüz yok. Amaç, öğrencilerin üzerine
 * inşa edeceği veri yapılarını ve çevrimi Renode'da gözle görülür kılmak.
 */
#ifndef ETOF_SCHEDULE_H
#define ETOF_SCHEDULE_H

#include <stdint.h>

/* Bir partition: adı ve her penceresinde bir kez çağrılan giriş noktası. */
typedef struct {
    const char *name;
    void (*entry)(void);
} partition_t;

/* Major frame içindeki bir zaman penceresi (ARINC653 "partition window"). */
typedef struct {
    uint8_t  partition;    /* partition tablosundaki indeks */
    uint32_t offset_ms;    /* major frame başlangıcına göre başlangıç */
    uint32_t duration_ms;  /* pencere süresi (bütçe) */
} window_t;

typedef struct {
    const partition_t *partitions;
    uint32_t           partition_count;
    const window_t    *windows;
    uint32_t           window_count;
    uint32_t           major_frame_ms;
} schedule_config_t;

/* Konfigürasyonu doğrular: pencereler çakışmamalı ve major frame'e sığmalı.
 * Başarılıysa 0, değilse hatalı pencerenin (indeks + 1) değerini döndürür. */
int schedule_validate(const schedule_config_t *cfg);

/* Verilen sayıda major frame çalıştırır (0 = sonsuz). Pencere bütçesini
 * aşan partition'lar "HM: deadline miss" olarak raporlanır. */
void schedule_run(const schedule_config_t *cfg, uint32_t frames);

#endif /* ETOF_SCHEDULE_H */
