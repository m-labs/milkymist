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
# $Id: test_CPI.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the CPI opcode.
"""

import base_test
from registers import Reg, SREG

class CPI_TestFail(base_test.TestFail): pass

class base_CPI(base_test.opcode_test):
	"""Generic test case for testing CPI opcode.

	CPI - Compare with Immediate
	opcode is '0011 KKKK dddd KKKK' where 16 <= d <= 31, 0 <= K <= 255

	Only registers PC and SREG should be changed.
	"""
	def setup(self):
		# Set SREG to zero
		self.setup_regs[Reg.SREG] = 0

		# Set the register values
		self.setup_regs[self.Rd] = self.Vd

		# Return the raw opcode
		return 0x3000 | ((self.Rd - 16) << 4) | ((self.Vk & 0xf0) << 4) | (self.Vk & 0xf)

	def analyze_results(self):
		self.reg_changed.append( Reg.SREG )
		
		# calculate the compare value
		res = (self.Vd - self.Vk) & 0xff

		expect_sreg = 0

		# calculate what we expect sreg to be (I and T should be zero)
		carry = (~self.Vd & self.Vk) | (self.Vk & res) | (res & ~self.Vd)
		H = ( carry >> 3) & 1
		C = ( carry >> 7) & 1
		N = ((res & 0x80) != 0)
		V = (( (self.Vd & ~self.Vk & ~res) | (~self.Vd & self.Vk & res)) >> 7) & 1
		expect_sreg += H          << SREG.H
		expect_sreg += N          << SREG.N
		expect_sreg += V          << SREG.V
		expect_sreg += (N ^ V)    << SREG.S
		expect_sreg += (res == 0) << SREG.Z
		expect_sreg += C          << SREG.C

		got_sreg = self.anal_regs[Reg.SREG]

		if expect_sreg != got_sreg:
			self.fail('CPI r%02d 0x%02x: 0x%02x 0x%02x: (expect=%02x, got=%02x)' % (
				self.Rd, self.Vk, self.Vd, self.Vk, expect_sreg, got_sreg))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class CPI_r%02d_v%02x_k%02x_TestFail(CPI_TestFail): pass

class test_CPI_r%02d_v%02x_k%02x(base_CPI):
	Rd = %d
	Vd = 0x%x
	Vk = 0x%x
	def fail(self,s):
		raise CPI_r%02d_v%02x_k%02x_TestFail, s
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
# automagically generate the test_CPI_rNN_vXX_kXX class definitions.
#
code = ''
for d in range(16,32):
	for vd,vk in vals:
		args = (d,vd,vk)*4
		code += template % args

exec code
