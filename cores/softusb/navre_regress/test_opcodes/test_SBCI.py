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
# $Id: test_SBCI.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the SBCI opcode.
"""

import base_test
from registers import Reg, SREG

class SBCI_TestFail(base_test.TestFail): pass

class base_SBCI(base_test.opcode_test):
	"""Generic test case for testing SBCI opcode.

	SBCI - Subtract Immediate with Carry. [Rd <- Rd - K - C]
	opcode is '0100 kkkk dddd kkkk' where d is 16-31 and K is 0-255

	Only registers PC, Rd and SREG should be changed.
	"""
	def setup(self):
		# Set SREG to zero or (Z and/or C flag set)
		self.setup_regs[Reg.SREG] = (self.C << SREG.C) | (self.Z << SREG.Z)

		# Set the register values
		self.setup_regs[self.Rd] = self.Vd

		# Return the raw opcode
		return 0x4000 | ((self.Rd - 16) << 4) | ((self.Vk & 0xf0) << 4) | (self.Vk & 0xf)

	def analyze_results(self):
		self.reg_changed.extend( [self.Rd, Reg.SREG] )
		
		# check that result is correct
		res = (self.Vd - self.Vk - self.C)
		expect = res & 0xff

		got = self.anal_regs[self.Rd]
		
		if expect != got:
			self.fail('SBCI r%02d, 0x%02x: 0x%02x - 0x%02x - %d = (expect=%02x, got=%02x)' % (
				self.Rd, self.Vk, self.Vd, self.Vk, self.C, expect, got))

		expect_sreg = 0

		# calculate what we expect sreg to be (I and T should be zero)
		carry = ((~self.Vd & self.Vk) | (self.Vk & res) | (res & ~self.Vd))
		H = (carry >> 3) & 1
		C = (carry >> 7) & 1
		V = (((self.Vd & ~self.Vk & ~res) | (~self.Vd & self.Vk & res)) >> 7) & 1
		N = ((expect & 0x80) != 0)
		expect_sreg += H             << SREG.H
		expect_sreg += V             << SREG.V
		expect_sreg += N             << SREG.N
		expect_sreg += (N ^ V)       << SREG.S
		expect_sreg += C             << SREG.C

		if expect == 0:
			expect_sreg += self.Z << SREG.Z

		got_sreg = self.anal_regs[Reg.SREG]

		if expect_sreg != got_sreg:
			self.fail('SBCI r%02d, 0x%02x: 0x%02x - 0x%02x - %d -> SREG (expect=%02x, got=%02x)' % (
				self.Rd, self.Vk, self.Vd, self.Vk, self.C, expect_sreg, got_sreg))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class SBCI_r%02d_v%02x_k%02x_C%d_Z%d_TestFail(SBCI_TestFail): pass

class test_SBCI_r%02d_v%02x_k%02x_C%d_Z%d(base_SBCI):
	Rd = %d
	Vd = 0x%x
	Vk = 0x%x
	C  = %d
	Z  = %d
	def fail(self,s):
		raise SBCI_r%02d_v%02x_k%02x_C%d_Z%d_TestFail, s
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
# automagically generate the test_SBCI_rNN_vXX_kXX_C[01]_Z[01] class definitions.
# For these, we don't want Rd=Rr as that is a special case handled below.
#
code = ''
for c,z in ((0,0), (1,0), (0,1), (1,1)):
	for d in range(16,32):
		for vd,vk in vals:
			args = (d,vd,vk,c,z)*4
			code += template % args

exec code
