#! /usr/bin/env python
###############################################################################
#
# simulavr - A simulator for the Atmel AVR family of microcontrollers.
# Copyright (C) 2001, 2002  Theodore A. Roth
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
###############################################################################
#
# $Id: registers.py,v 1.1 2004/07/31 00:59:32 rivetwa Exp $
#

"""Define Names for AVR registers.
"""

class Reg:
	"""Map names to register numbers as used by gdb.
	"""
	R00 = 0
	R01 = 1
	R02 = 2
	R03 = 3
	R04 = 4
	R05 = 5
	R06 = 6
	R07 = 7
	R08 = 8
	R09 = 9
	R10 = 10
	R11 = 11
	R12 = 12
	R13 = 13
	R14 = 14
	R15 = 15
	R16 = 16
	R17 = 17
	R18 = 18
	R19 = 19
	R20 = 20
	R21 = 21
	R22 = 22
	R23 = 23
	R24 = 24
	R25 = 25
	R26 = 26
	R27 = 27
	R28 = 28
	R29 = 29
	R30 = 30
	R31 = 31

	SREG = 32
	SP   = 33
	PC   = 34

class SREG:
	C = 0
	Z = 1
	N = 2
	V = 3
	S = 4
	H = 5
	T = 6
	I = 7

class Addr:
	"""Give symoblic names to various sram addresses.
	"""
	SREG = 0x5f
	SPH  = 0x5e
	SPL  = 0x5d
