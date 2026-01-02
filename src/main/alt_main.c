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
#include "fsl_assert.h"
#include "DbgUtil.h"
#endif

#if defined(SITL_BUILD)
int main(int argc, char *argv[])
{
    parseArguments(argc, argv);
#else
int main(void)
{
#endif
    #warning "In Main Function"

    while (true) {
#if defined(SITL_BUILD)
        
#endif

#if defined(MIMXRT_1062)
        indicateAlive();
#endif

    }
}
