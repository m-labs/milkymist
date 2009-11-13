/*
 * Milkymist VJ SoC (Software)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __HW_SYSCTL_H
#define __HW_SYSCTL_H

#include <hw/common.h>

#define CSR_GPIO_IN		MMPTR(0x80001000)
#define CSR_GPIO_OUT		MMPTR(0x80001004)
#define CSR_GPIO_INTEN		MMPTR(0x80001008)

#define CSR_TIMER0_CONTROL	MMPTR(0x80001010)
#define CSR_TIMER0_COMPARE	MMPTR(0x80001014)
#define CSR_TIMER0_COUNTER	MMPTR(0x80001018)

#define CSR_TIMER1_CONTROL	MMPTR(0x80001020)
#define CSR_TIMER1_COMPARE	MMPTR(0x80001024)
#define CSR_TIMER1_COUNTER	MMPTR(0x80001028)

#define TIMER_MATCH		(0x01)
#define TIMER_AUTORESTART	(0x02)
#define TIMER_ENABLE		(0x04)

#define CSR_SYSTEM_ID		MMPTR(0x8000103c)

#endif /* __HW_SYSCTL_H */
