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
# $Id: test_BRBS.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the BRBS opcode.

The following opcodes are pseudonyms for BRBS:
  BREQ, BRCS, BRLO, BRMI, BRLT, BRHS, BRTS, BRVS, BRIE
"""

import base_test
from registers import Reg

class BRBS_TestFail(base_test.TestFail): pass

class base_BRBS(base_test.opcode_test):
	"""Generic test case for testing BRBS opcode.

	Branch if sreg bit set.
	opcode is '1111 00kk kkkk ksss' where k is pc offset and s is sreg bit.

	No registers except for PC should have changed.
	"""
	# FIXME: Offsets can wrap around ends of flash. Need to mask expect value
	# with size of flash. Once done, need to test it.
	k = 20
	def setup(self):
		# set the sreg bit we are interrested in
		self.setup_regs[Reg.SREG] = self.val << self.bit

		return 0xF000 | self.bit | ((self.k&0x7f)<<3)

	def analyze_results(self):
		self.is_pc_checked = 1

		expect = self.setup_regs[Reg.PC] + 2
		if self.val == 1:
			expect += (self.k * 2)

		got = self.anal_regs[Reg.PC]

		if expect != got:
			self.fail('PC not incremented: expect=%x, got=%x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class BRBS_bit%d_is_%d_TestFail(BRBS_TestFail): pass

class test_BRBS_bit%d_is_%d(base_BRBS):
	bit = %d
	val = %d
	def fail(self,s):
		raise BRBS_bit%d_is_%d_TestFail, s
"""

#
# automagically generate the test_BRBS_bitN_is_[01] class definitions
#
code = ''
for b in range(7): # do not test bit 7
	for v in range(2):
		code += template % (b,v,b,v,b,v,b,v)
exec code
