/*
 * This file is part of Cleanflight.
 *
 * Cleanflight is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Cleanflight is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Cleanflight.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include "platform.h"

#include "drivers/persistent.h"
// TODO: Add this back in once exti support is added.
// #include "drivers/exti.h"
#include "drivers/nvic.h"
#include "drivers/system.h"
#include "fsl_src.h"

// Debug
#include "DbgUtil.h"

void forcedSystemResetWithoutDisablingCaches(void)
{
    persistentObjectWrite(PERSISTENT_OBJECT_RESET_REASON, RESET_NONE);
    __disable_irq();

    // Calling the mapped system reset ISR will cause a soft system reset
    NVIC_SystemReset(); 
}

void enableGPIOPowerUsageAndNoiseReductions(void)
{
    // TODO: Need to see if this is even required. May be able to run with defaults from system init.
}

bool isMPUSoftReset(void)
{
    // Soft reset source is defined as user manually setting the reset. NOTE: If a CPU lockup resulted in SYSRESETQ
    // being set instead rather than NVIC_SystemReset, this may lead to a false positive soft reset.
    if (cachedRccCsrValue & kSRC_LockupSysResetFlag)
        return true;
    else
        return false;
}

uint32_t systemBootloaderAddress(void)
{
    // DFU not yet supported, so cannot use DFU to upload firmware. Could possibly 
    // port DFU to work with SDK, assign GPIO pin for DFU detect, and jump to image but
    // most 106Xs on the market can be programmed via JTAG and an on-board companion MCU.
    // So not super critical.
    return 0;
}

void systemInit(void)
{
    BOARD_ConfigMPU();
    BOARD_InitBootPins();
    BOARD_InitBootClocks();
    BOARD_InitBootPeripherals();

    // Slap some early debug lines in
    initUartComms(115200);
    reroutConsoleDebug(6, 115200);
    // Clear the console before init
    PRINTF("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\r");
    PRINTF("UART INIT COMPLETE\n\r");
    
    // Dump persistent objects
    PRINTF("Magic: %u\n\r", persistentObjectRead(PERSISTENT_OBJECT_MAGIC));
    PRINTF("Reset Reason: %u\n\r", persistentObjectRead(PERSISTENT_OBJECT_RESET_REASON));


    // Configure NVIC preempt/priority groups
    __NVIC_SetPriorityGrouping(NVIC_PRIORITY_GROUPING);

    // cache reset source for later use
    cachedRccCsrValue = SRC_GetResetStatusFlags(SRC);
    SRC_ClearResetStatusFlags(SRC, cachedRccCsrValue);

    enableGPIOPowerUsageAndNoiseReductions();

    // Init cycle counter
    cycleCounterInit();

    // Enable system ticks at a 1 msec rate. TODO: Need to see if there is a better way to globally set the requested tick rate.
    // Otherwise its a bit of the wild west across boards to determine what the systic rate should be.
    SysTick_Config(SystemCoreClock / 1000U);
}
