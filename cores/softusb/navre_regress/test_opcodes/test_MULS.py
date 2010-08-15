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
# $Id: test_MULS.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the MULS opcode.
"""

import base_test
from registers import Reg, SREG

class MULS_TestFail(base_test.TestFail): pass

class base_MULS(base_test.opcode_test):
	"""Generic test case for testing MULS opcode.

	description: multiply two signed numbers and save the result in R1:R0 (highb:lowbyte)
	opcode:      0000 0010 dddd rrrr   16 <= d,r <= 31
	changes:     R1,R0,SREG: C set if R15 set, Z set if result 0x0000
	"""
	def setup(self):
		# Set SREG to zero or only C flag set
		self.setup_regs[Reg.SREG] = 0x0

		# Set the register values
		self.setup_regs[self.Rd] = self.Vd & 0xff
		self.setup_regs[self.Rr] = self.Vr & 0xff

		# Return the raw opcode
		return 0x0200 | (self.Rr & 0x0f) | (self.Rd & 0x0f) << 4 

	def analyze_results(self):
		self.reg_changed.extend( [Reg.R00, Reg.R01, Reg.SREG] )

		if (self.Vd & 0x80):
			# Vd is a negative 8 bit number, so convert to 32 bit
			self.Vd |= -256

		if (self.Vr & 0x80):
			# Vd is a negative 8 bit number, so convert to 32 bit
			self.Vr |= -256

		# check that result is correct
		res = (self.Vd * self.Vr)
		expect = res & 0xffff

		got = self.anal_regs[Reg.R00] | self.anal_regs[Reg.R01] << 8
		
		if expect != got:
			self.fail('MULS calc r%02d, r%02d: %d * %d = (expect=%04x, got=%04x)' % (
				self.Rd, self.Rr, self.Vd, 
				self.Vr, expect, got))

		expect_sreg = 0

		# calculate what we expect sreg to be 
		C = (expect & 0x8000) >> 15
		expect_sreg += (expect == 0) << SREG.Z
		expect_sreg += C  << SREG.C
		
		got_sreg = self.anal_regs[Reg.SREG]

		if expect_sreg != got_sreg:
			self.fail('MULS flag setting: 0x%d * 0x%d -> SREG (expect=%02x, got=%02x)' % (
				self.Vd, self.Vr, expect_sreg, got_sreg))
		
#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class MULS_rd%02d_vd%02x_rr%02d_vr%02x_TestFail(MULS_TestFail): pass

class test_MULS_rd%02d_vd%02x_rr%02d_vr%02x(base_MULS):
	Rd = %d
	Vd = %d
	Rr = %d
	Vr = %d
	def fail(self,s):
		raise MULS_rd%02d_vd%02x_rr%02d_vr%02x_TestFail, s
"""

#
# Define a list of test values such that we all the cases of SREG bits being set.
#
vals = (
( 0x00, 0x00),
( 0xff, 0x01),
( 0x01, 0xff),
( 0xff, 0xff),
( 0xff, 0x00),
( 0x00, 0xb3),
( 0x80, 0x7f),
( 0x80, 0x80),
( 0x7f, 0x7f),
( 0x4d, 0x4d),
)

#
# automagically generate the test_MULS_rdNN_vdXX_rrNN_vrXX_C[01] class definitions.
# For these, we don't want Rd=Rr as that is a special case handled below.
#
code = ''
step = 3
for d in range(16,32,step):
	for r in range(17,32,step):
		for vd,vr in vals:
			args = (d, vd, r, vr)*4
			code += template % args

#
# Special case when Rd==Rr, make sure Vd==Vr.
#
for d in range(16,32,step):
	for vd,vr in vals:
		args = (d, vd, d, vd)*4
		code += template % args
exec code
