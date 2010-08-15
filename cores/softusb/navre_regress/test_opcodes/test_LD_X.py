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
# $Id: test_LD_X.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the LD_X opcode.
"""

import base_test
from registers import Reg, SREG

class LD_X_TestFail(base_test.TestFail): pass

class base_LD_X(base_test.opcode_test):
	"""Generic test case for testing LD_X opcode.

	LD_X - Load Indirect from data space to Register using index X

	Operation: Rd <- (X)

	opcode is '1001 000d dddd 1100' where 0 <= d <= 31

	Only registers PC and Rd should be changed.
	"""
	def setup(self):
		# Set the register values
		self.setup_regs[self.Rd] = 0
		self.setup_regs[Reg.R26] = (self.X & 0xff)
		self.setup_regs[Reg.R27] = (self.X >> 8)

		# set up the val in memory
		self.mem_byte_write( self.X, self.Vd )

		# Return the raw opcode
		return 0x900C | (self.Rd << 4)

	def analyze_results(self):
		self.reg_changed.extend( [self.Rd] )
		
		# check that result is correct
		expect = self.Vd
		got = self.anal_regs[self.Rd]
		
		if expect != got:
			self.fail('LD_X: expect=%02x, got=%02x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class LD_X_r%02d_X%04x_v%02x_TestFail(LD_X_TestFail): pass

class test_LD_X_r%02d_X%04x_v%02x(base_LD_X):
	Rd = %d
	X = 0x%x
	Vd = 0x%x
	def fail(self,s):
		raise LD_X_r%02d_X%04x_v%02x_TestFail, s
"""

#
# automagically generate the test_LD_X_rNN_vXX class definitions.
#
code = ''
for d in range(0,32):
	for x in (0x10f, 0x1ff):
		for v in (0xaa, 0x55):
			args = (d,x,v)*4
			code += template % args
exec code
