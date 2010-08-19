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
# $Id: test_BSET.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the BSET opcode.

The following opcodes are pseudonyms for BSET:
  SEC, SEZ, SEN, SEV, SES, SEH, SET, SEI
"""

import base_test
from registers import Reg

class BSET_TestFail(base_test.TestFail): pass

class base_BSET(base_test.opcode_test):
	"""Generic test case for testing BSET opcode.

	Bit set in SREG.
	opcode is '1001 0100 0sss 1000' where s is the sreg bit.

	No registers except for PC and SREG should have changed.
	"""
	def setup(self):
		# set the sreg to zero
		self.setup_regs[Reg.SREG] = 0

		return 0x9408 | (self.bit << 4)

	def analyze_results(self):
		# check that correct SREG bit is set
		self.reg_changed.append(Reg.SREG)
		expect = (1 << self.bit)
		got = self.anal_regs[Reg.SREG]
		if expect != got:
			self.fail('SREG bit %d not set: expect=%02x, got=%02x' % (self.bit, expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class BSET_bit%d_TestFail(BSET_TestFail): pass

class test_BSET_bit%d(base_BSET):
	bit = %d
	def fail(self,s):
		raise BSET_bit%d_TestFail, s
"""

#
# automagically generate the test_BSET_bitN_is_[01] class definitions
#
code = ''
for b in range(7): # do not test bit 7
	code += template % (b,b,b,b)
exec code
