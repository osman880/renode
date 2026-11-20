/*
 * ETOF - RTOS üzerinde ARINC653 Prensipleri ile Aviyonik Sürücü Geliştirme
 * Başlangıç demosu: 3 partition'lı statik major frame (100 ms).
 *
 *   0 ms        40 ms        80 ms    100 ms
 *   |  P1_NAV   |  P2_COMM   | P3_HM  |
 */
#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/gpio.h"

#include "schedule.h"

#define LED_PIN 25u

static uint32_t comm_counter;

static void p1_nav(void)
{
    gpio_xor_mask(1u << LED_PIN); /* gözle görülür "iş": LED toggle */
}

static void p2_comm(void)
{
    comm_counter++;
}

static void p3_health(void)
{
    printf("P3_HM: alive, comm_counter=%lu\n", (unsigned long)comm_counter);
}

static const partition_t partitions[] = {
    { "P1_NAV",  p1_nav    },
    { "P2_COMM", p2_comm   },
    { "P3_HM",   p3_health },
};

static const window_t major_frame[] = {
    { 0,  0, 40 },
    { 1, 40, 40 },
    { 2, 80, 20 },
};

static const schedule_config_t config = {
    .partitions      = partitions,
    .partition_count = sizeof partitions / sizeof partitions[0],
    .windows         = major_frame,
    .window_count    = sizeof major_frame / sizeof major_frame[0],
    .major_frame_ms  = 100,
};

int main(void)
{
    stdio_init_all();
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);

    printf("ETOF ARINC653 demo baslatildi\n");

    int bad = schedule_validate(&config);
    if (bad != 0) {
        printf("CONFIG ERROR: window %d gecersiz\n", bad - 1);
        for (;;) tight_loop_contents();
    }
    printf("Schedule OK: %lu partition, major frame %lu ms\n",
           (unsigned long)config.partition_count,
           (unsigned long)config.major_frame_ms);

    schedule_run(&config, 0);
    return 0;
}
