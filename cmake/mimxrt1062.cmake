include(cortex-m7)

# GENERAL TODO PORT: This was thrown together as an initial stab to get things configuring. A much more 
# in-depth pass will have to be made later. 

# 1062 does not have a separate set of driver dirs from its SDK - Grab all in one go.
# If other MIMXRT10xx targets are added, it may be of use to split some common SDK components out.
set(MIMXRT1062_SDK_SRC_DIR "${MAIN_LIB_DIR}/main/MIMXRT1062")

# Setup the flat include directory for the drivers (NOTE - migration from SDK *requires* this as all their
# cross-driver includes are flat)
set(MIMXRT1062_SDK_BOARD_DIR "${MIMXRT1062_SDK_SRC_DIR}/main/MIMXRT1062/board")
set(MIMXRT1062_SDK_CMSIS_DIR "${MIMXRT1062_SDK_SRC_DIR}/main/MIMXRT1062/CMSIS")
set(MIMXRT1062_SDK_USB_DIR "${MIMXRT1062_SDK_SRC_DIR}/main/MIMXRT1062/USB")
set(MIMXRT1062_SDK_DRIVER_DIR "${MIMXRT1062_SDK_SRC_DIR}/main/MIMXRT1062/drivers")
set(MIMXRT1062_SDK_COMPONENT_DIR "${MIMXRT1062_SDK_SRC_DIR}/main/MIMXRT1062/component")
set(MIMXRT1062_SDK_UTIL_DIR "${MIMXRT1062_SDK_SRC_DIR}/main/MIMXRT1062/USB/utilities")
set(MIMXRT1062_SDK_XIP_DIR "${MIMXRT1062_SDK_SRC_DIR}/main/MIMXRT1062/xip")

file(GLOB MIMXRT1062_SDK_SRC "${MIMXRT1062_SDK_SRC_DIR}/*.c")

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
 
set(MIMXRT1062_INCLUDE_DIRS
    ${MIMXRT1062_SDK_BOARD_DIR}
    ${MIMXRT1062_SDK_CMSIS_DIR}
    ${MIMXRT1062_SDK_USB_DIR}
    ${MIMXRT1062_SDK_DRIVER_DIR}
    ${MIMXRT1062_SDK_COMPONENT_DIR}
    ${MIMXRT1062_SDK_UTIL_DIR}
    ${MIMXRT1062_SDK_XIP_DIR}
)

set(MIMXRT1062_DEFINITIONS
    ${CORTEX_M7_DEFINITIONS}
    DATA_SECTION_IS_CACHEABLE=0
    _DEBUG=1                       # For now, force debug on.
    DEBUG
    SDK_DEBUGCONSOLE=1
    XIP_EXTERNAL_FLASH=1
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
)

set(MIMXRT1062_COMPILE_OPTIONS
     -fno-common 
     -g3 
     -gdwarf-4 
     -c 
     -ffunction-sections 
     -fdata-sections 
     -fno-builtin 
     -fmerge-constants
)

function(target_mimxrt1062)
    target_mimxrt106x(
        SOURCES ${MIMXRT1062_SDK_SRC}
        COMPILE_DEFINITIONS ${MIMXRT1062_DEFINITIONS}
        COMPILE_OPTIONS ${CORTEX_M7_COMMON_OPTIONS} ${CORTEX_M7_COMPILE_OPTIONS} ${MIMXRT1062_COMPILE_OPTIONS}
        INCLUDE_DIRECTORIES ${MIMXRT1062_INCLUDE_DIRS}
        LINK_OPTIONS ${CORTEX_M7_COMMON_OPTIONS} ${CORTEX_M7_LINK_OPTIONS}
        OPTIMIZATION -O2
        ${ARGN}
    )
endfunction()

# DVJ6B is the initial target device, however actual 1062xxxxA and 1062xxxxB differ by such a small
# ammount that it is most likely not worth defining a target for each. Additionally, FLASH is external
# so no need for compile definitions calling it out.
# However, for the initial porting
# effort this looks to be the pattern so it will be followed.
set(mimxrt1062dvj6b_COMPILE_DEFINITIONS
        CPU_MIMXRT1062DVJ6B
)

function(target_mimxrt1062dvj6b name)
    target_at32f43x(
        NAME ${name}
        STARTUP startup_mimxrt1062.c
        #SOURCES
        COMPILE_DEFINITIONS ${mimxrt1062dvj6b_COMPILE_DEFINITIONS}
        LINKER_SCRIPT mimxrt1062xxxxb
        # SVD
        ${ARGN}
    )
endfunction()
