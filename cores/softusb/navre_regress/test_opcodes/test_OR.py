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
# $Id: test_OR.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the OR opcode.
"""

import base_test
from registers import Reg, SREG

class OR_TestFail(base_test.TestFail): pass

class base_OR(base_test.opcode_test):
	"""Generic test case for testing OR opcode.

	OR - Logical OR
	opcode is '0010 10rd dddd rrrr' where r and d are registers (d is destination).

	Only registers PC, Rd and SREG should be changed.
	"""
	def setup(self):
		# Set SREG to have only V set (opcode should clear it)
		self.setup_regs[Reg.SREG] = 1 << SREG.V

		# Set the register values
		self.setup_regs[self.Rd] = self.Vd
		self.setup_regs[self.Rr] = self.Vr

		# Return the raw opcode
		return 0x2800 | (self.Rd << 4) | ((self.Rr & 0x10) << 5) | (self.Rr & 0xf)

	def analyze_results(self):
		self.reg_changed.extend( [self.Rd, Reg.SREG] )
		
		# check that result is correct
		expect = ((self.Vd | self.Vr) & 0xff)

		got = self.anal_regs[self.Rd]
		
		if expect != got:
			self.fail('OR r%02d, r%02d: 0x%02x | 0x%02x = (expect=%02x, got=%02x)' % (
				self.Rd, self.Rr, self.Vd, self.Vr, expect, got))

		expect_sreg = 0

		# calculate what we expect sreg to be (I, T, H, V and C should be zero)
		V = 0
		N = ((expect & 0x80) != 0)
		expect_sreg += N             << SREG.N
		expect_sreg += (N ^ V)       << SREG.S
		expect_sreg += (expect == 0) << SREG.Z

		got_sreg = self.anal_regs[Reg.SREG]

		if expect_sreg != got_sreg:
			self.fail('OR r%02d, r%02d: 0x%02x | 0x%02x -> SREG (expect=%02x, got=%02x)' % (
				self.Rd, self.Rr, self.Vd, self.Vr, expect_sreg, got_sreg))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class OR_rd%02d_vd%02x_rr%02d_vr%02x_TestFail(OR_TestFail): pass

class test_OR_rd%02d_vd%02x_rr%02d_vr%02x(base_OR):
	Rd = %d
	Vd = 0x%x
	Rr = %d
	Vr = 0x%x
	def fail(self,s):
		raise OR_rd%02d_vd%02x_rr%02d_vr%02x_TestFail, s
"""

#
# Define a list of test values such that we test all the cases of SREG bits being set.
#
vals = (
( 0x00, 0x00 ),
( 0xff, 0x00 ),
( 0xfe, 0x01 ),
( 0x0f, 0x00 ),
( 0x0f, 0xf0 ),
( 0x01, 0x02 )
)

#
# automagically generate the test_OR_rdNN_vdXX_rrNN_vrXX class definitions.
#
code = ''
for d in range(0,32,4):
	for r in range(0,32,4):
		for vd,vr in vals:
			if d == r:
				vr = vd
			args = (d,vd,r,vr)*4
			code += template % args

exec code
