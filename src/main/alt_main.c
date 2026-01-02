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

#include <stdbool.h>
#include <stdint.h>

#if defined(MIMXRT_1062)
#include "fsl_clock.h"
#include "DbgUtil.h"
#endif

int main(void) {

    /* Init board hardware. */
    BOARD_ConfigMPU();
    BOARD_InitBootPins();
    BOARD_InitBootClocks();
    BOARD_InitBootPeripherals();

    // Blink three times to say we are alive.
    blinkLed(3);
    while(1)
    {
    	// Blink 2 times to indicate we are in the main processing loop
    	blinkLed(2);

    	SDK_DelayAtLeastUs(2000000, SDK_DEVICE_MAXIMUM_CPU_CLOCK_FREQUENCY);
    }
    return 0 ;
}
