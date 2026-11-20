cmake_minimum_required(VERSION 3.13)

# PICO_SDK_PATH ortam değişkeni ya da -DPICO_SDK_PATH=... ile verilmelidir.
include(pico_sdk_import.cmake)

project(etof_arinc653 C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

pico_sdk_init()

add_executable(etof_demo
    src/main.c
    src/schedule.c
)

target_include_directories(etof_demo PRIVATE src)
target_compile_options(etof_demo PRIVATE -Wall -Wextra -Werror)
target_link_libraries(etof_demo pico_stdlib)

# Konsol çıktısı UART0 üzerinden (GP0/GP1). Renode da uart0'ı dinliyor.
pico_enable_stdio_uart(etof_demo 1)
pico_enable_stdio_usb(etof_demo 0)
