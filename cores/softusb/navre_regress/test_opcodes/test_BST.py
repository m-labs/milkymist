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
# $Id: test_BST.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the BST opcode.
"""

import base_test
from registers import Reg, SREG

class BST_TestFail(base_test.TestFail): pass

class base_BST(base_test.opcode_test):
	"""Generic test case for testing BST opcode.

	Bit store from bit in register to T flag in SREG.
	opcode is '1111 101d dddd 0bbb' where d is register and b is the register bit.

	Only registers PC and SREG should be changed.
	"""
	def setup(self):
		# set SREG and the given register's bits to complement of expected T value
		if self.T == 0:
			self.setup_regs[Reg.SREG] = 0xff
			self.setup_regs[self.reg] = 0xff & ~(1 << self.bit)
		else:
			self.setup_regs[Reg.SREG] = 0x00
			self.setup_regs[self.reg] = (1 << self.bit)

		return 0xFA00 | (self.reg << 4) | self.bit

	def analyze_results(self):
		self.reg_changed.append(Reg.SREG)

		# check that register value is correct
		if self.T == 0:
			expect = 0xff & ~(1 << SREG.T)
		else:
			expect = (1 << SREG.T)

		got = self.anal_regs[Reg.SREG]
		if expect != got:
			self.fail('r%02d bit %d not T(%d): expect=%02x, got=%02x' % (
				self.reg, self.bit, self.T, expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class BST_r%02d_bit%d_T%d_TestFail(BST_TestFail): pass

class test_BST_r%02d_bit%d_T%d(base_BST):
	reg = %d
	bit = %d
	T   = %d
	def fail(self,s):
		raise BST_r%02d_bit%d_T%d_TestFail, s
"""

#
# automagically generate the test_BST_rNN_bitN_T[01] class definitions
#
code = ''
for t in (0,1):
	for r in range(32):
		for b in range(8):
			code += template % (r,b,t, r,b,t, r,b,t, r,b,t)
exec code
