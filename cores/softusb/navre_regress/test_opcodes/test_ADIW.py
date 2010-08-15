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
# $Id: test_ADIW.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the ADIW opcode.
"""

import base_test
from registers import Reg, SREG

class ADIW_TestFail(base_test.TestFail): pass

class base_ADIW(base_test.opcode_test):
	"""Generic test case for testing ADIW opcode.

	Add Immediate to Word. [Rd+1:Rd <- Rd+1:Rd + K]
	opcode is '1001 0110 KKdd KKKK' where d is {24,26,28,30}, and K is [0,63]

	Only registers PC, Rd and SREG should be changed.
	"""
	def setup(self):
		# Set SREG to zero
		self.setup_regs[Reg.SREG] = 0x00

		# Set the register values
		self.setup_regs[self.Rd]   = (self.vd & 0xff)
		self.setup_regs[self.Rd+1] = (self.vd >> 8)

		# Return the raw opcode
		return 0x9600 | (((self.Rd/2)-12) << 4) | ((self.vk & 0x30) << 2) | (self.vk & 0xf)

	def analyze_results(self):
		self.reg_changed.extend( [self.Rd, self.Rd+1, Reg.SREG] )
		
		# check that result is correct
		res = (self.vd + self.vk)
		expect = res & 0xffff

		got = self.anal_regs[self.Rd] + (self.anal_regs[self.Rd+1] << 8)
		
		if expect != got:
			self.fail('ADIW r%02d, r%02x: 0x%04x + 0x%02x = (expect=%02x, got=%02x)' % (
				self.Rd, self.vk, self.vd, self.vk, expect, got))

		expect_sreg = 0

		# calculate what we expect sreg to be (I, T and H should be zero)
		V = ((~self.vd & res) >> 15) & 1
		N = ((expect >> 15) & 1)
		expect_sreg += V             << SREG.V
		expect_sreg += N             << SREG.N
		expect_sreg += (N ^ V)       << SREG.S
		expect_sreg += (expect == 0) << SREG.Z
		expect_sreg += (((~res & self.vd) >> 15) & 1)  << SREG.C

		got_sreg = self.anal_regs[Reg.SREG]

		if expect_sreg != got_sreg:
			self.fail('ADIW r%02d, r%02x: 0x%04x + 0x%02x -> SREG (expect=%02x, got=%02x)' % (
				self.Rd, self.vk, self.vd, self.vk, expect_sreg, got_sreg))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class ADIW_r%02d_v%04x_k%02x_TestFail(ADIW_TestFail): pass

class test_ADIW_r%02d_v%04x_k%02x(base_ADIW):
	Rd = %d
	vd = 0x%x
	vk = 0x%x
	def fail(self,s):
		raise ADIW_r%02d_v%04x_k%02x_TestFail, s
"""

# reg val, k val (0x00 <= k <= 0x3f)
vals = (
	( 0x0000, 0x00 ),
	( 0x0000, 0x3f ),
	( 0x00ff, 0x01 ),
	( 0xffbf, 0x3f ),
	( 0xffff, 0x01 ),
	( 0x7fff, 0x01 ),
	( 0x8000, 0x00 ),
	( 0x8000, 0x01 )
)

#
# automagically generate the test_ADIW_rdNN_vdXX_rrNN_vrXX_C[01] class definitions.
# For these, we don't want Rd=Rr as that is a special case handled below.
#
code = ''
for d in range(24,32,2):
	for vd,vk in vals:
		args = (d,vd,vk)*4
		code += template % args
exec code
