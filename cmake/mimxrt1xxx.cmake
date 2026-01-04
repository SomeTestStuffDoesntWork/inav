include(mimxrt106x)

include(CMakeParseArguments)

option(DEBUG_HARDFAULTS "Enable debugging of hard faults via custom handler")
option(SEMIHOSTING "Enable semihosting")

message("-- DEBUG_HARDFAULTS: ${DEBUG_HARDFAULTS}, SEMIHOSTING: ${SEMIHOSTING}")

# TODO PORT - These are all generic CMSIS - need these. CMSIS specifics are in device specific cmake
set(CMSIS_DIR "${MAIN_LIB_DIR}/main/CMSIS")
set(CMSIS_INCLUDE_DIR "${CMSIS_DIR}/Core/Include")
set(CMSIS_DSP_DIR "${MAIN_LIB_DIR}/main/CMSIS/DSP")
set(CMSIS_DSP_INCLUDE_DIR "${CMSIS_DSP_DIR}/Include")

# DSP use common
set(CMSIS_DSP_DIR "${MAIN_LIB_DIR}/main/CMSIS/DSP")
set(CMSIS_DSP_INCLUDE_DIR "${CMSIS_DSP_DIR}/Include")

set(CMSIS_DSP_SRC
    BasicMathFunctions/arm_scale_f32.c
    BasicMathFunctions/arm_sub_f32.c
    BasicMathFunctions/arm_mult_f32.c
    BasicMathFunctions/arm_offset_f32.c
    TransformFunctions/arm_rfft_fast_f32.c
    TransformFunctions/arm_cfft_f32.c
    TransformFunctions/arm_rfft_fast_init_f32.c
    TransformFunctions/arm_cfft_radix8_f32.c
    TransformFunctions/arm_bitreversal2.S
    CommonTables/arm_common_tables.c
    ComplexMathFunctions/arm_cmplx_mag_f32.c
    StatisticsFunctions/arm_max_f32.c
    StatisticsFunctions/arm_rms_f32.c
    StatisticsFunctions/arm_std_f32.c
    StatisticsFunctions/arm_mean_f32.c
)
list(TRANSFORM CMSIS_DSP_SRC PREPEND "${CMSIS_DSP_DIR}/Source/")

set(MIMXRT1XXX_STARTUP_DIR "${MAIN_SRC_DIR}/startup")

# These soures * should * be common enough across other NXP crossover processors, but 
# each new processor should be tested against these during support testing.
main_sources(MIMXRT1XXX_ASYNCFATFS_SRC
    #io/asyncfatfs/asyncfatfs.c
    #io/asyncfatfs/fat_standard.c
)

main_sources(MIMXRT1XXX_MSC_SRC
    #msc/mimxrt1xxx_msc_diskio.c
    #msc/emfat.c
    #msc/emfat_file.c
)

main_sources(MIMXRT1XXX_VCP_SRC
    drivers/serial_usb_vcp_mimxrt1xxx.c
    #drivers/usb_io.c
)

main_sources(MIMXRT1XXX_SDCARD_SRC
    #drivers/sdcard/sdcard.c
    #drivers/sdcard/sdcard_spi.c
    #drivers/sdcard/sdcard_sdio.c
    #drivers/sdcard/sdcard_standard.c
)

set(MIMXRT1XXX_INCLUDE_DIRS
    "${CMSIS_INCLUDE_DIR}"
    "${CMSIS_DSP_INCLUDE_DIR}"
    "${MAIN_SRC_DIR}/target"
)

set(MIMXRT1XXX_DEFINITIONS
)

set(MIMXRT1XXX_DEFAULT_HSE_MHZ 8)
set(MIMXRT1XXX_LINKER_DIR "${MAIN_SRC_DIR}/target/link")
set(MIMXRT1XXX_COMPILE_OPTIONS
    -ffunction-sections
    -fdata-sections
    -fno-common
)

set(MIMXRT1XXX_LINK_LIBRARIES
    -lm
    -lc
)

if(SEMIHOSTING)
    list(APPEND MIMXRT1XXX_LINK_LIBRARIES --specs=rdimon.specs -lrdimon)
    list(APPEND MIMXRT1XXX_DEFINITIONS SEMIHOSTING)
else()
    list(APPEND MIMXRT1XXX_LINK_LIBRARIES -lnosys)
endif()

set(MIMXRT1XXX_LINK_OPTIONS
    --specs=nano.specs
    -static
    -Wl,-gc-sections
    -Wl,-L${MIMXRT1XXX_LINKER_DIR}
    -Wl,--cref
    -Wl,--no-wchar-size-warning
    -Wl,--print-memory-usage
    -Wl,--no-warn-rwx-segments
)
# Get target features
macro(get_mimxrt1xxx_target_features output_var dir target_name)
    execute_process(COMMAND "${CMAKE_C_COMPILER}" -E -dD -D${ARGV2} "${ARGV1}/target.h"
        ERROR_VARIABLE _errors
        RESULT_VARIABLE _result
        OUTPUT_STRIP_TRAILING_WHITESPACE
        OUTPUT_VARIABLE _contents)

    if(NOT _result EQUAL 0)
        message(FATAL_ERROR "error extracting features for MIMXRT106x target ${ARGV2}: ${_errors}")
    endif()

    string(REGEX MATCH "#define[\t ]+USE_VCP" HAS_VCP ${_contents})
    if(HAS_VCP)
        list(APPEND ${ARGV0} VCP)
    endif()
    string(REGEX MATCH "define[\t ]+USE_FLASHFS" HAS_FLASHFS ${_contents})
    if(HAS_FLASHFS)
        list(APPEND ${ARGV0} FLASHFS)
    endif()
    string(REGEX MATCH "define[\t ]+USE_SDCARD" HAS_SDCARD ${_contents})
    if (HAS_SDCARD)
        list(APPEND ${ARGV0} SDCARD)
        string(REGEX MATCH "define[\t ]+USE_SDCARD_SDIO" HAS_SDIO ${_contents})
        if (HAS_SDIO)
            list(APPEND ${ARGV0} SDIO)
        endif()
    endif()
    if(HAS_FLASHFS OR HAS_SDCARD)
        list(APPEND ${ARGV0} MSC)
    endif()
endmacro()

function(add_hex_target name exe hex)
    add_custom_target(${name} ALL
        cmake -E env PATH="$ENV{PATH}"
        ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${exe}> ${hex}
        BYPRODUCTS ${hex}
    )
endfunction()

function(add_bin_target name exe bin)
    add_custom_target(${name}
        cmake -E env PATH="$ENV{PATH}"
        ${CMAKE_OBJCOPY} -Obinary $<TARGET_FILE:${exe}> ${bin}
        BYPRODUCTS ${bin}
    )
endfunction()

function(generate_map_file target)
    if(CMAKE_VERSION VERSION_LESS 3.15)
        set(map "$<TARGET_FILE:${target}>.map")
    else()
        set(map "$<TARGET_FILE_DIR:${target}>/$<TARGET_FILE_BASE_NAME:${target}>.map")
    endif()
    target_link_options(${target} PRIVATE "-Wl,-Map,${map}")
endfunction()

# TODO PORT - Definitely need to get the linker script brought over pronto.
function(set_linker_script target script)
    set(script_path ${MIMXRT1XXX_LINKER_DIR}/${args_LINKER_SCRIPT}.ld)
    if(NOT EXISTS ${script_path})
        message(FATAL_ERROR "linker script ${script_path} doesn't exist")
    endif()
    set_target_properties(${target} PROPERTIES LINK_DEPENDS ${script_path})
    target_link_options(${elf_target} PRIVATE -T${script_path})
endfunction()

function(add_mimxrt1xxx_executable)
    cmake_parse_arguments(
        args
        # Boolean arguments
        ""
        # Single value arguments
        "FILENAME;NAME;OPTIMIZATION;OUTPUT_BIN_FILENAME;OUTPUT_HEX_FILENAME;OUTPUT_TARGET_NAME"
        # Multi-value arguments
        "COMPILE_DEFINITIONS;COMPILE_OPTIONS;INCLUDE_DIRECTORIES;LINK_OPTIONS;LINKER_SCRIPT;SOURCES"
        # Start parsing after the known arguments
        ${ARGN}
    )

    # There are several source files that cannot be included for this device and must be fully omitted. 
    # Any required symbols are swapped out in the 'targets' directory.
    main_sources(MIMXRT1XXXX_SWAPPED_SOURCES
        drivers/persistent.c # Persistent implementations can vary wildly across chip peripherals. Must define a device-specific version.
    )

    exclude(args_SOURCES "${MIMXRT1XXXX_SWAPPED_SOURCES}")

    set(elf_target ${args_NAME}.elf)
    add_executable(${elf_target})
    target_sources(${elf_target} PRIVATE ${args_SOURCES})
    target_include_directories(${elf_target} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${args_INCLUDE_DIRECTORIES} ${MIMXRT1XXX_INCLUDE_DIRS})
    target_compile_definitions(${elf_target} PRIVATE ${args_COMPILE_DEFINITIONS})
    target_compile_options(${elf_target} PRIVATE ${MIMXRT1XXX_COMPILE_OPTIONS} ${args_COMPILE_OPTIONS})
    if(WARNINGS_AS_ERRORS)
        target_compile_options(${elf_target} PRIVATE -Werror)
    endif()
    if (IS_RELEASE_BUILD)
        target_compile_options(${elf_target} PRIVATE ${args_OPTIMIZATION})
        target_link_options(${elf_target} PRIVATE ${args_OPTIMIZATION})
    endif()
    target_link_libraries(${elf_target} PRIVATE ${MIMXRT1XXX_LINK_LIBRARIES})
    target_link_options(${elf_target} PRIVATE ${MIMXRT1XXX_LINK_OPTIONS} ${args_LINK_OPTIONS})
    generate_map_file(${elf_target})
    set_linker_script(${elf_target} ${args_LINKER_SCRIPT})
    if(args_FILENAME)
        set(basename ${CMAKE_BINARY_DIR}/${args_FILENAME})
        set(hex_filename ${basename}.hex)
        add_hex_target(${args_NAME} ${elf_target} ${hex_filename})
        set(bin_filename ${basename}.bin)
        add_bin_target(${args_NAME}.bin ${elf_target} ${bin_filename})
    endif()
    if(args_OUTPUT_BIN_FILENAME)
        set(${args_OUTPUT_BIN_FILENAME} ${bin_filename} PARENT_SCOPE)
    endif()
    if(args_OUTPUT_TARGET_NAME)
        set(${args_OUTPUT_TARGET_NAME} ${elf_target} PARENT_SCOPE)
    endif()
    if(args_OUTPUT_HEX_FILENAME)
        set(${args_OUTPUT_HEX_FILENAME} ${hex_filename} PARENT_SCOPE)
    endif()
endfunction()

#  Main function of MIMXRT1XXX
function(target_mimxrt1xxx)
    if(NOT arm-none-eabi STREQUAL TOOLCHAIN)
        return()
    endif()
    # Parse keyword arguments
    cmake_parse_arguments(
        args
        # Boolean arguments
        "DISABLE_MSC;BOOTLOADER"
        # Single value arguments
        "HSE_MHZ;LINKER_SCRIPT;NAME;OPENOCD_TARGET;OPTIMIZATION;STARTUP;SVD"
        # Multi-value arguments
        "COMPILE_DEFINITIONS;COMPILE_OPTIONS;INCLUDE_DIRECTORIES;LINK_OPTIONS;SOURCES;MSC_SOURCES;MSC_INCLUDE_DIRECTORIES;VCP_SOURCES;VCP_INCLUDE_DIRECTORIES"
        # Start parsing after the known arguments
        ${ARGN}
    )
    set(name ${args_NAME})

    if (args_HSE_MHZ)
        # HSE is not directly supported by NXP SDK, but it is internally converted in clocks file.
        set(hse_mhz ${args_HSE_MHZ})
    else()
        set(hse_mhz ${MIMXRT1XXX_DEFAULT_HSE_MHZ})
    endif()

    set(target_sources ${MIMXRT1XXX_STARTUP_DIR}/${args_STARTUP})
    list(APPEND target_sources ${args_SOURCES})

    file(GLOB target_c_sources "${CMAKE_CURRENT_SOURCE_DIR}/*.c")
    file(GLOB target_h_sources "${CMAKE_CURRENT_SOURCE_DIR}/*.h")
    list(APPEND target_sources ${target_c_sources} ${target_h_sources})

    set(target_include_directories ${args_INCLUDE_DIRECTORIES})

    set(target_definitions ${MIMXRT1XXX_DEFINITIONS} ${COMMON_COMPILE_DEFINITIONS})

    get_mimxrt1xxx_target_features(features "${CMAKE_CURRENT_SOURCE_DIR}" ${name})
    set_property(TARGET ${elf_target} PROPERTY FEATURES ${features})

    if(VCP IN_LIST features)
        list(APPEND target_sources ${MIMXRT1XXX_VCP_SRC} ${args_VCP_SOURCES})
        list(APPEND target_include_directories ${args_VCP_INCLUDE_DIRECTORIES})
    endif()
    if(SDCARD IN_LIST features)
        # NOTE: These are NOT set by this 
        list(APPEND target_sources ${MIMXRT1XXX_SDCARD_SRC} ${MIMXRT1XXX_ASYNCFATFS_SRC})
    endif()

    set(msc_sources)
    if(NOT args_DISABLE_MSC AND MSC IN_LIST features)
        list(APPEND target_include_directories ${args_MSC_INCLUDE_DIRECTORIES})
        list(APPEND msc_sources ${MIMXRT1XXX_MSC_SRC} ${args_MSC_SOURCES})
        list(APPEND target_definitions USE_USB_MSC)
        if(FLASHFS IN_LIST features)
            list(APPEND msc_sources ${MIMXRT1XXX_MSC_FLASH_SRC})
        endif()
        if (SDCARD IN_LIST features)
            list(APPEND msc_sources ${MIMXRT1XXX_MSC_SDCARD_SRC})
        endif()
    endif()

    math(EXPR hse_value "${hse_mhz} * 1000000")
    list(APPEND target_definitions "HSE_VALUE=${hse_value}")

    if (MSP_UART) 
        list(APPEND target_definitions "MSP_UART=${MSP_UART}")
    endif()

    if(args_COMPILE_DEFINITIONS)
        list(APPEND target_definitions ${args_COMPILE_DEFINITIONS})
    endif()
    if(DEBUG_HARDFAULTS)
        list(APPEND target_definitions DEBUG_HARDFAULTS)
    endif()

    string(TOLOWER ${PROJECT_NAME} lowercase_project_name)
    set(binary_name ${lowercase_project_name}_${FIRMWARE_VERSION}_${name})
    if(DEFINED BUILD_SUFFIX AND NOT "" STREQUAL "${BUILD_SUFFIX}")
        set(binary_name "${binary_name}_${BUILD_SUFFIX}")
    endif()

    # Main firmware
    add_mimxrt1xxx_executable(
        NAME ${name}
        FILENAME ${binary_name}
        SOURCES ${target_sources} ${msc_sources} ${CMSIS_DSP_SRC} ${COMMON_SRC}
        COMPILE_DEFINITIONS ${target_definitions}
        COMPILE_OPTIONS ${args_COMPILE_OPTIONS}
        INCLUDE_DIRECTORIES ${target_include_directories}
        LINK_OPTIONS ${args_LINK_OPTIONS}
        LINKER_SCRIPT ${args_LINKER_SCRIPT}
        OPTIMIZATION ${args_OPTIMIZATION}

        OUTPUT_BIN_FILENAME main_bin_filename
        OUTPUT_HEX_FILENAME main_hex_filename
        OUTPUT_TARGET_NAME main_target_name

    )

    set_property(TARGET ${main_target_name} PROPERTY OPENOCD_TARGET ${args_OPENOCD_TARGET})
    set_property(TARGET ${main_target_name} PROPERTY OPENOCD_DEFAULT_INTERFACE atlink)
    set_property(TARGET ${main_target_name} PROPERTY SVD ${args_SVD})

    setup_firmware_target(${main_target_name} ${name} ${ARGN})

    if(args_BOOTLOADER)
        message("Bootloader for MIMXRT1XXX Target Not Supported! No bootloader will be built")
    endif()
endfunction()
