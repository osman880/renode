#include "schedule.h"

#include <stdio.h>
#include "pico/stdlib.h"

int schedule_validate(const schedule_config_t *cfg)
{
    uint32_t prev_end = 0;

    for (uint32_t i = 0; i < cfg->window_count; i++) {
        const window_t *w = &cfg->windows[i];
        uint32_t end = w->offset_ms + w->duration_ms;

        if (w->partition >= cfg->partition_count) return (int)i + 1;
        if (w->duration_ms == 0)                  return (int)i + 1;
        if (w->offset_ms < prev_end)              return (int)i + 1; /* çakışma / sıra hatası */
        if (end > cfg->major_frame_ms)            return (int)i + 1; /* frame'e sığmıyor */
        prev_end = end;
    }
    return 0;
}

static void wait_until_us(uint64_t t_us)
{
    while (time_us_64() < t_us) {
        tight_loop_contents();
    }
}

void schedule_run(const schedule_config_t *cfg, uint32_t frames)
{
    uint64_t frame_start = time_us_64();

    for (uint32_t f = 0; frames == 0 || f < frames; f++) {
        for (uint32_t i = 0; i < cfg->window_count; i++) {
            const window_t    *w = &cfg->windows[i];
            const partition_t *p = &cfg->partitions[w->partition];
            uint64_t win_start = frame_start + (uint64_t)w->offset_ms * 1000u;
            uint64_t win_end   = win_start + (uint64_t)w->duration_ms * 1000u;

            wait_until_us(win_start);
            printf("[%8llu us] frame %lu window %lu -> %s\n",
                   (unsigned long long)(time_us_64()),
                   (unsigned long)f, (unsigned long)i, p->name);

            p->entry();

            /* Kooperatif model: süre aşımını ancak partition döndükten sonra
             * görebiliyoruz. Gerçek zamansal izolasyon için timer kesmesiyle
             * preemption gerekir (Faz 3 hedefi). */
            if (time_us_64() > win_end) {
                printf("HM: deadline miss in %s (window %lu)\n",
                       p->name, (unsigned long)i);
            }
        }
        frame_start += (uint64_t)cfg->major_frame_ms * 1000u;
    }
}
