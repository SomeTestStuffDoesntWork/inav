/*
 * This file is part of INAV.
 *
 * INAV free software. You can redistribute
 * this software and/or modify this software under the terms of the
 * GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * INAV distributed in the hope that it
 * will be useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software.
 *
 * If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * An implementation of persistent data storage utilizing RTC backup data register.
 * Retains values written across software resets and boot loader activities.
 */

#include <stdint.h>
#include "platform.h"

#include "drivers/persistent.h"
#include "drivers/system.h"
#include "fsl_snvs_lp.h"
#include "fsl_src.h"

// Number of LPGR registers supported. LPGR registers are not consecutive so only a portion of the map
// may be supported.
#define SUPPORTED_LPGR_REGS 8
#define PERSISTENT_OBJECT_MAGIC_VALUE (('i' << 24)|('N' << 16)|('a' << 8)|('v' << 0))

uint32_t persistentObjectRead(persistentObjectId_e id)
{
    if(id < SUPPORTED_LPGR_REGS)
    {
        return SNVS->LPGPR[id];
    }

    // ELSE:
    return 0;
}

void persistentObjectWrite(persistentObjectId_e id, uint32_t value)
{
    // NOTE: this can only be written while in supervisor mode (IE priviledged for ARMv7)
    // This *assumes* that the mode is priviledged, but if later down the road this is reused 
    // and say an RTOS is added that executes tasks in user mode, make sure that the mode is properly
    // managed. Otherwise, the module will lockout any writes and report a security violation.
    if(id < SUPPORTED_LPGR_REGS)
    {
        SNVS->LPGPR[id] = value;
    }
}

void persistentObjectRTCEnable(void)
{
    /* enable the pwc clock interface */
    SNVS_LP_Init(SNVS);

    // Persistent objects should now be available - Don't touch the control register's lock fields
    // Out of reset R/W is unlocked but as soon as written, the value is locked until reset.
}

void persistentObjectInit(void)
{
    // Configure and enable RTC for backup register access

    persistentObjectRTCEnable();

    // XXX Magic value checking may be sufficient

    // See note in inav_system_mimxrt1062.c for implications of using kSRC_LockupSysResetFlag as indicator of soft reset.
    uint32_t wasSoftReset = SRC_GetResetStatusFlags(SRC) | kSRC_LockupSysResetFlag;
    if (!wasSoftReset || (persistentObjectRead(PERSISTENT_OBJECT_MAGIC) != PERSISTENT_OBJECT_MAGIC_VALUE)) {
        for (int i = 1; i < PERSISTENT_OBJECT_COUNT; i++) {
            persistentObjectWrite(i, 0);
        }
        persistentObjectWrite(PERSISTENT_OBJECT_MAGIC, PERSISTENT_OBJECT_MAGIC_VALUE);
    }
}
