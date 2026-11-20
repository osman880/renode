*** Settings ***
Documentation     Demo firmware'in Renode'daki RP2040 üzerinde açılıp
...               major frame çevrimini doğru sırayla çalıştırdığını doğrular.
Suite Setup       Setup
Suite Teardown    Teardown
Test Setup        Reset Emulation
Test Teardown     Test Teardown
Resource          ${RENODEKEYWORDS}

*** Keywords ***
Create Pico
    Execute Command    $rp2040=@${RP2040}
    Execute Command    $firmware=@${FIRMWARE}
    Execute Command    include @${PROJECT}/sim/pico.resc
    Create Terminal Tester    sysbus.uart0    timeout=10

*** Test Cases ***
Firmware Acilmali Ve Schedule Dogrulanmali
    Create Pico
    Start Emulation
    Wait For Line On Uart    ETOF ARINC653 demo baslatildi
    Wait For Line On Uart    Schedule OK: 3 partition, major frame 100 ms

Partition Pencereleri Dogru Sirada Calismali
    Create Pico
    Start Emulation
    Wait For Line On Uart    frame 0 window 0 -> P1_NAV
    Wait For Line On Uart    frame 0 window 1 -> P2_COMM
    Wait For Line On Uart    frame 0 window 2 -> P3_HM
    Wait For Line On Uart    P3_HM: alive, comm_counter=1
    Wait For Line On Uart    frame 1 window 0 -> P1_NAV

Deadline Miss Olmamali
    Create Pico
    Start Emulation
    Wait For Line On Uart    frame 3 window 2 -> P3_HM
    Should Not Be On Uart    HM: deadline miss    timeout=1
