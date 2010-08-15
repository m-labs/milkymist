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
# $Id: test_CPC.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the CPC opcode.
"""

import base_test
from registers import Reg, SREG

class CPC_TestFail(base_test.TestFail): pass

class base_CPC(base_test.opcode_test):
	"""Generic test case for testing CPC opcode.

	CPC - Compare with Carry
	opcode is '0000 01rd dddd rrrr' where 0 <= d,r <= 31

	Only registers PC and SREG should be changed.
	"""
	def setup(self):
		# Set SREG to have only C set to self.C
		self.setup_regs[Reg.SREG] = (self.C << SREG.C) + (self.Z << SREG.Z)

		# Set the register values
		self.setup_regs[self.Rd] = self.Vd
		self.setup_regs[self.Rr] = self.Vr

		# Return the raw opcode
		return 0x0400 | (self.Rd << 4) | ((self.Rr & 0x10) << 5) | (self.Rr & 0xf)

	def analyze_results(self):
		self.reg_changed.append( Reg.SREG )
		
		# calculate the compare value
		res = (self.Vd - self.Vr - self.C) & 0xff

		expect_sreg = 0

		# calculate what we expect sreg to be (I and T should be zero)
		carry = (~self.Vd & self.Vr) | (self.Vr & res) | (res & ~self.Vd)
		H = ( carry >> 3) & 1
		C = ( carry >> 7) & 1
		N = ((res & 0x80) != 0)
		V = (( (self.Vd & ~self.Vr & ~res) | (~self.Vd & self.Vr & res)) >> 7) & 1
		expect_sreg += H          << SREG.H
		expect_sreg += N          << SREG.N
		expect_sreg += V          << SREG.V
		expect_sreg += (N ^ V)    << SREG.S
		expect_sreg += C          << SREG.C

		# Z unchanged from previous operation if res is zero. Cleared otherwise.
		# In our case, prev Z is self.Z
		if res == 0:
			expect_sreg += self.Z << SREG.Z
		else:
			# Z flag already zero in expect_sreg
			pass

		got_sreg = self.anal_regs[Reg.SREG]

		if expect_sreg != got_sreg:
			self.fail('CPC r%02d r%02d: 0x%02x 0x%02x: (expect=%02x, got=%02x)' % (
				self.Rd, self.Rr, self.Vd, self.Vr, expect_sreg, got_sreg))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class CPC_rd%02d_v%02x_rr%02d_v%02x_C%d_Z%d_TestFail(CPC_TestFail): pass

class test_CPC_rd%02d_v%02x_rr%02d_v%02x_C%d_Z%d(base_CPC):
	Rd = %d
	Vd = 0x%x
	Rr = %d
	Vr = 0x%x
	C  = %d
	Z  = %d
	def fail(self,s):
		raise CPC_rd%02d_v%02x_rr%02d_v%02x_C%d_Z%d_TestFail, s
"""

#
# Define a list of test values such that we test all the cases of SREG bits being set.
#
vals = (
( 0x00, 0x00 ),
( 0xff, 0xff ),
( 0xff, 0x00 ),
( 0x00, 0xff ),
( 0xaa, 0x55 ),
( 0x55, 0xaa ),
( 0x01, 0x00 ),
( 0x00, 0x01 )
)

#
# automagically generate the test_CPC_rNN_vXX_C[01]_Z[01] class definitions.
#
code = ''
for c,z in [ (0,0), (0,1), (1,0), (1,1) ]:
	for d in range(0,32,8):
		for r in range(1,32,8):
			for vd,vr in vals:
				args = (d,vd,r,vr,c,z)*4
				code += template % args

exec code
