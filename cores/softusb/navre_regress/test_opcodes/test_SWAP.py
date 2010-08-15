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
# $Id: test_SWAP.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the SWAP opcode.
"""

import base_test
from registers import Reg

class SWAP_TestFail(base_test.TestFail): pass

class base_SWAP(base_test.opcode_test):
	"""Generic test case for testing SWAP opcode.

	The derived class must provide the reg member and the fail method.

	This opcode should swap the nibbles of the given register.

	PC should be incremented by two bytes (1 word). Data sheet uses 1 word and
	gdb interface uses 2 bytes. [checked by base_test.opcode_test class]
	"""
	def setup(self):
		self.setup_regs[self.reg] = 0xa5

		# opcode is '1001 010d dddd 0010' where d is reg number (0-31)
		return 0x9402 | (self.reg << 4)

	def analyze_results(self):
		self.reg_changed.append(self.reg)
		if self.anal_regs[self.reg] != 0x5a:
			self.fail('nibbles not swapped: old=a5, new=%02x' % (self.anal_regs[self.reg]))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class SWAP_r%02d_TestFail(SWAP_TestFail): pass

class test_SWAP_r%02d(base_SWAP):
	reg = %d
	def fail(self,s):
		raise SWAP_r%02d_TestFail, s
"""

#
# automagically generate the test_SWAP_* class definitions
#
code = ''
for i in range(32):
	code += template % (i,i,i,i)
exec code
