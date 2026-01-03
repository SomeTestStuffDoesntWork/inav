/*
 * This file is part of INAV.
 *
 * INAV is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * INAV is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with INAV.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef DBG_UTIL_H
#define DBG_UTIL_H
#include <stdint.h>

void indicateAlive(void);

void blinkLed(uint32_t num_blink);

void reroutConsoleDebug(uint8_t uart_idx, uint32_t baud);

void initUartComms(uint32_t baud_rate);

#endif /* DBG_UTIL_H */