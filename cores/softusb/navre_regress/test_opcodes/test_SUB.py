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
# $Id: test_SUB.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the SUB opcode.
"""

import base_test
from registers import Reg, SREG

class SUB_TestFail(base_test.TestFail): pass

class base_SUB(base_test.opcode_test):
	"""Generic test case for testing SUB opcode.

	SUB - Subtract without Carry. [Rd <- Rd - Rr]
	opcode is '0001 10rd dddd rrrr' where r and d are registers (d is destination).

	Only registers PC, Rd and SREG should be changed.
	"""
	def setup(self):
		# Set SREG to zero
		self.setup_regs[Reg.SREG] = 0

		# Set the register values
		self.setup_regs[self.Rd] = self.Vd
		self.setup_regs[self.Rr] = self.Vr

		# Return the raw opcode
		return 0x1800 | (self.Rd << 4) | ((self.Rr & 0x10) << 5) | (self.Rr & 0xf)

	def analyze_results(self):
		self.reg_changed.extend( [self.Rd, Reg.SREG] )
		
		# check that result is correct
		res = (self.Vd - self.Vr)
		expect = res & 0xff

		got = self.anal_regs[self.Rd]
		
		if expect != got:
			self.fail('SUB r%02d, r%02d: 0x%02x - 0x%02x = (expect=%02x, got=%02x)' % (
				self.Rd, self.Rr, self.Vd, self.Vr, expect, got))

		expect_sreg = 0

		# calculate what we expect sreg to be (I and T should be zero)
		carry = ((~self.Vd & self.Vr) | (self.Vr & res) | (res & ~self.Vd))
		H = (carry >> 3) & 1
		C = (carry >> 7) & 1
		V = (((self.Vd & ~self.Vr & ~res) | (~self.Vd & self.Vr & res)) >> 7) & 1
		N = ((expect & 0x80) != 0)
		expect_sreg += H             << SREG.H
		expect_sreg += V             << SREG.V
		expect_sreg += N             << SREG.N
		expect_sreg += (N ^ V)       << SREG.S
		expect_sreg += C             << SREG.C
		expect_sreg += (expect == 0) << SREG.Z

		got_sreg = self.anal_regs[Reg.SREG]

		if expect_sreg != got_sreg:
			self.fail('SUB r%02d, r%02d: 0x%02x - 0x%02x -> SREG (expect=%02x, got=%02x)' % (
				self.Rd, self.Rr, self.Vd, self.Vr, expect_sreg, got_sreg))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class SUB_rd%02d_vd%02x_rr%02d_vr%02x_TestFail(SUB_TestFail): pass

class test_SUB_rd%02d_vd%02x_rr%02d_vr%02x(base_SUB):
	Rd = %d
	Vd = 0x%x
	Rr = %d
	Vr = 0x%x
	def fail(self,s):
		raise SUB_rd%02d_vd%02x_rr%02d_vr%02x_TestFail, s
"""

#
# Define a list of test values such that we all the cases of SREG bits being set.
#
vals = (
( 0x00, 0x00 ),
( 0xff, 0x00 ),
( 0xfe, 0x01 ),
( 0x0f, 0x00 ),
( 0x0f, 0xf0 ),
( 0x01, 0x02 ),
( 0x80, 0x01 )
)

#
# automagically generate the test_SUB_rdNN_vdXX_rrNN_vrXX class definitions.
# For these, we don't want Rd=Rr as that is a special case handled below.
#
code = ''
for d in range(0,32,4):
	for r in range(1,32,4):
		for vd,vr in vals:
			args = (d,vd,r,vr)*4
			code += template % args

# make sure things work if Rd == Rr
for d in range(2,32,4):
	for vd,vr in vals:
		args = (d,vd,d,vd)*4
		code += template % args
exec code
