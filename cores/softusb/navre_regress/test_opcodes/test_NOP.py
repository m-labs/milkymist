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
# $Id: test_NOP.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the NOP opcode.
"""

import base_test
from registers import Reg

class NOP_TestFail(base_test.TestFail): pass

class test_NOP(base_test.opcode_test):
	"""Test the NOP opcode.

	A NOP should only change the PC (PC <- PC + 1). If any other registers
	change, test fails.

	PC should be incremented by two bytes (1 word). Data sheet uses 1 word and
	gdb interface uses 2 bytes.
	"""

	def setup(self):
		return 0x0000

	def analyze_results(self):
		# the base class checks PC and that no registers were changed.
		pass
