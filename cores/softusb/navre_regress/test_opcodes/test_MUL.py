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
# $Id: test_MUL.py,v 0.5 josef
#

"""Test the MUL opcode.
"""

import base_test
from registers import Reg, SREG

class MUL_TestFail(base_test.TestFail): pass

class base_MUL(base_test.opcode_test):
	"""Generic test case for testing MUL opcode.

	description: multiply two unsigned numbers and save the
	             result in R1:R0 (highb:lowbyte)
	opcode:      1001 11rd dddd rrrr
	changes:     R1,R0,SREG: C set if R15 set, Z set if result 0x0000
	"""
	def setup(self):
		# Set SREG to zero or only C flag set
		self.setup_regs[Reg.SREG] = 0x0

		# Set the register values
		self.setup_regs[self.Rd] = self.Vd
		self.setup_regs[self.Rr] = self.Vr

		# Return the raw opcode
		return 0x9C00 | (self.Rr & 0x0f) | (self.Rd & 0x1f) << 4 | (self.Rr & 0x10) << 5

	def analyze_results(self):
		self.reg_changed.extend( [Reg.R00,Reg.R01, Reg.SREG] )
		
		# check that result is correct
		res = (self.Vd * self.Vr)
		expect = res & 0xffff

		got = self.anal_regs[Reg.R00] | self.anal_regs[Reg.R01] << 8
		
		if expect != got:
			self.fail('MUL calc r%02d, r%02d: 0x%02x * 0x%02x = (expect=%d, got=%d)' % (
				self.Rd, self.Rr, self.Vd,
				self.Vr, expect, got))

		expect_sreg = 0

		# calculate what we expect sreg to be
		C = (expect & 0x8000) >> 15
		expect_sreg += (expect == 0) << SREG.Z
		expect_sreg += C  << SREG.C

		got_sreg = self.anal_regs[Reg.SREG]

		if expect_sreg != got_sreg:
			self.fail('MUL flag setting: 0x%d * 0x%d -> SREG (expect=%02x, got=%02x)' % (
				self.Vd, self.Vr, expect_sreg, got_sreg))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class MUL_rd%02d_vd%02x_rr%02d_vr%02xTestFail(MUL_TestFail): pass

class test_MUL_rd%02d_vd%02x_rr%02d_vr%02x(base_MUL):
	Rd = %d
	Vd = 0x%x
	Rr = %d
	Vr = 0x%x
	def fail(self,s):
		raise MUL_rd%02d_vd%02x_rr%02d_vr%02xTestFail, s
"""

#
# Define a list of test values such that we all the cases of SREG bits being set.
#
vals = (
( 0x00, 0x00 ),
( 0x01, 0x00 ),
( 0x00, 0x4d ),
( 0xff, 0xff ),
( 0xff, 0x4d ),
( 0x01, 0xff ),
)

#
# automagically generate the test_MUL_rdNN_vdXX_rrNN_vrXX class definitions.
# For these, we don't want Rd=Rr as that is a special case handled below.
#
code = ''
step = 8
for d in range(0,32,step):
	for r in range(1,32,8):
		for vd,vr in vals:
			args = (d,vd,r,vr)*4
			code += template % args

#
# This is a special case (Rd == Rr) make sure that Vd == Vr.
#
for d in range(0,32,step):
	for vd,vr in vals:
		args = (d, vd, d, vd)*4
		code += template % args
exec code
