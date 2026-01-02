include(cortex-m7)

# MIMXRT106X Common Package *******************************************************************************************
set(MIMXRT106X_SDK_SRC_DIR "${MAIN_LIB_DIR}/main/MIMXRT1XXX/MIMXRT106X")

# Setup the flat include directory for the drivers (NOTE - migration from SDK *requires* this as all their
# cross-driver includes are flat)
set(MIMXRT106X_SDK_CMSIS_DIR "${MIMXRT106X_SDK_SRC_DIR}/CMSIS")
set(MIMXRT106X_SDK_USB_DIR "${MIMXRT106X_SDK_SRC_DIR}/USB")
set(MIMXRT106X_SDK_DRIVER_DIR "${MIMXRT106X_SDK_SRC_DIR}/drivers")
set(MIMXRT106X_SDK_COMPONENT_DIR "${MIMXRT106X_SDK_SRC_DIR}/component")
set(MIMXRT106X_SDK_UTIL_DIR "${MIMXRT106X_SDK_SRC_DIR}/utilities")
set(MIMXRT106X_SDK_XIP_DIR "${MIMXRT106X_SDK_SRC_DIR}/xip")

file(GLOB_RECURSE MIMXRT106X_SDK_SRC "${MIMXRT106X_SDK_SRC_DIR}/*.c")

# Don't think that any 1062-specific files are required yet. Abstraction layer where these would
# be swapped out should be at the 10xx level, not MCU specific. TODO PORT - After port is functional, 
# remove old template.
# main_sources(AT32F4_SRC
#     target/system_at32f435_437.c
#     config/config_streamer_at32f43x.c
#     config/config_streamer_ram.c
#     config/config_streamer_extflash.c 
#     drivers/adc_at32f43x.c
#     drivers/i2c_application.c
#     drivers/bus_i2c_at32f43x.c
#     drivers/bus_spi_at32f43x
#     drivers/serial_uart_hal_at32f43x.c
#     drivers/serial_uart_at32f43x.c
# 
#     drivers/system_at32f43x.c
#     drivers/timer.c
#     drivers/timer_impl_stdperiph_at32.c
#     drivers/timer_at32f43x.c
#     drivers/uart_inverter.c
#     drivers/dma_at32f43x.c
# )
 
set(MIMXRT106X_INCLUDE_DIRS
    ${MIMXRT106X_SDK_CMSIS_DIR}
    ${MIMXRT106X_SDK_USB_DIR}
    ${MIMXRT106X_SDK_DRIVER_DIR}
    ${MIMXRT106X_SDK_COMPONENT_DIR}
    ${MIMXRT106X_SDK_UTIL_DIR}
    ${MIMXRT106X_SDK_XIP_DIR}
)

set(MIMXRT106X_DEFINITIONS
    ${CORTEX_M7_DEFINITIONS}
    DATA_SECTION_IS_CACHEABLE=0
    SDK_DEBUGCONSOLE=1
    XIP_EXTERNAL_FLASH=1
    XIP_BOOT_HEADER_ENABLE=1
    USB_STACK_BM
    FSL_OSA_BM_TASK_ENABLE=0
    FSL_OSA_BM_TIMER_CONFIG=0
    SDK_OS_BAREMETAL
    MCUXPRESSO_SDK
    SDK_OS_BAREMETAL
    CR_INTEGER_PRINTF
    PRINTF_FLOAT_ENABLE=0
    __MCUXPRESSO
    __USE_CMSIS
    MIMXRT_106X
)

set(MIMXRT106X_COMPILE_OPTIONS
     -fno-common 
     -g3 
     -gdwarf-4 
     -c 
     -ffunction-sections 
     -fdata-sections 
     -fno-builtin 
     -fmerge-constants
)

function(target_mimxrt106x)
    target_mimxrt1xxx(
        SOURCES ${MIMXRT106X_SDK_SRC}
        COMPILE_DEFINITIONS ${MIMXRT106X_DEFINITIONS}
        COMPILE_OPTIONS ${CORTEX_M7_COMMON_OPTIONS} ${CORTEX_M7_COMPILE_OPTIONS} ${MIMXRT106X_COMPILE_OPTIONS}
        INCLUDE_DIRECTORIES ${MIMXRT106X_INCLUDE_DIRS}
        LINK_OPTIONS ${CORTEX_M7_COMMON_OPTIONS} ${CORTEX_M7_LINK_OPTIONS}
        OPTIMIZATION -O2
        ${ARGN}
    )
endfunction()


# MIMXRT1062 Targets **************************************************************************************************

set(MIMXRT1062_SDK_SRC_DIR "${MAIN_LIB_DIR}/main/MIMXRT1XXX/MIMXRT1062")

set(MIMXRT1062_SDK_BOARD_DIR "${MIMXRT1062_SDK_SRC_DIR}/board")
set(MIMXRT1062_SDK_DEVICE_DIR "${MIMXRT1062_SDK_SRC_DIR}/device")
set(MIMXRT1062_SDK_XIP_DIR "${MIMXRT1062_SDK_SRC_DIR}/xip")
set(MIMXRT1062_SDK_UTIL_DIR "${MIMXRT1062_SDK_SRC_DIR}/utilities")

file(GLOB_RECURSE MIMXRT1062_SDK_SRC "${MIMXRT1062_SDK_SRC_DIR}/*.c")

set(MIMXRT1062_INCLUDE_DIRS
    ${MIMXRT1062_SDK_BOARD_DIR}
    ${MIMXRT1062_SDK_DEVICE_DIR}
    ${MIMXRT1062_SDK_XIP_DIR}
    ${MIMXRT1062_SDK_UTIL_DIR}
)

# DVJ6B is the initial target device, however actual 1062xxxxA and 1062xxxxB differ by such a small
# ammount that it is most likely not worth defining a target for each.
# Flash on these chips is external and need to be called out by the flash size of the target.
set(mimxrt1062dvj6b_COMPILE_DEFINITIONS
        CPU_MIMXRT1062DVJ6B
        MIMXRT_1062
)

function(target_mimxrt1062dvj6b name)
    target_mimxrt106x(
        NAME ${name}
        STARTUP startup_mimxrt1062.c
        INCLUDE_DIRECTORIES ${MIMXRT1062_INCLUDE_DIRS}
        SOURCES ${MIMXRT1062_SDK_SRC}
        COMPILE_DEFINITIONS ${mimxrt1062dvj6b_COMPILE_DEFINITIONS}
        LINKER_SCRIPT mimxrt1062xxxxb
        # SVD
        ${ARGN}
    )
endfunction()
