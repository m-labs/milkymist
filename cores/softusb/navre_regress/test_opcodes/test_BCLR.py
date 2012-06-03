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
# $Id: test_BCLR.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the BCLR opcode.

The following opcodes are pseudonyms for BCLR:
  CLC, CLZ, CLN, CLV, CLS, CLH, CLT, CLI
"""

import base_test
from registers import Reg

class BCLR_TestFail(base_test.TestFail): pass

class base_BCLR(base_test.opcode_test):
	"""Generic test case for testing BCLR opcode.

	Bit set in SREG.
	opcode is '1001 0100 1sss 1000' where s is the sreg bit.

	No registers except for PC and SREG should have changed.
	"""
	def setup(self):
		# set the sreg to 0xff (all ones so that we check that only one bit was cleared)
		self.setup_regs[Reg.SREG] = 0xff
		
		return 0x9488 | (self.bit << 4)

	def analyze_results(self):
		# check that correct SREG bit is cleared
		self.reg_changed.append(Reg.SREG)
		expect = 0xff & ~(1 << self.bit)
		got = self.anal_regs[Reg.SREG]
		if expect != got:
			self.fail('SREG bit %d not set: expect=%02x, got=%02x' % (self.bit, expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class BCLR_bit%d_TestFail(BCLR_TestFail): pass

class test_BCLR_bit%d(base_BCLR):
	bit = %d
	def fail(self,s):
		raise BCLR_bit%d_TestFail, s
"""

#
# automagically generate the test_BCLR_bitN_is_[01] class definitions
#
code = ''
for b in range(8):
	code += template % (b,b,b,b)
exec code
