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

#include "mimxrt106x_utils.h"

#define NUM_UID_WORDS 2U

static const uint32_t* FUSE_ADDRESSES[] = {0x410, 0x420};

uint32_t getDeviceUid(uint8_t uid_word)
{
    if(uid_word > NUM_UID_WORDS)
    {
        return 0;
    }    
    return *(FUSE_ADDRESSES[uid_word]);
}