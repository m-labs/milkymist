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
# $Id: test_LDI.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the LDI opcode.
"""

import base_test
from registers import Reg, SREG

class LDI_TestFail(base_test.TestFail): pass

class base_LDI(base_test.opcode_test):
	"""Generic test case for testing LDI opcode.

	LDI - Load Immediate
	opcode is '1110 kkkk dddd kkkk' where 16 <= d <= 31

	Only registers PC and Rd should be changed.
	"""
	def setup(self):
		# Set the register values
		self.setup_regs[self.Rd] = 0

		# Return the raw opcode
		return 0xE000 | ((self.Rd - 16) << 4) | ((self.Vd & 0xf0) << 4) | (self.Vd & 0xf)

	def analyze_results(self):
		self.reg_changed.extend( [self.Rd] )
		
		# check that result is correct
		exp = self.Vd

		got = self.anal_regs[self.Rd]
		
		if exp != got:
			self.fail('LDI r%02d: 0x%02x = (expect=%02x, got=%02x)' % (
				self.Rd, self.Vd, exp, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class LDI_r%02d_v%02x_TestFail(LDI_TestFail): pass

class test_LDI_r%02d_v%02x(base_LDI):
	Rd = %d
	Vd = 0x%x
	def fail(self,s):
		raise LDI_r%02d_v%02x_TestFail, s
"""

#
# Define a list of test values such that we test all the cases of SREG bits being set.
#
vals = (
0x00,
0xff,
0xaa,
0xf0,
0x01
)

#
# automagically generate the test_LDI_rNN_vXX class definitions.
#
code = ''
for d in range(16,32):
	for vd in vals:
		args = (d,vd)*4
		code += template % args

exec code
