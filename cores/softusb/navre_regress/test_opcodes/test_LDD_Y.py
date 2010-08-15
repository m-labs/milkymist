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
# $Id: test_LDD_Y.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the LDD_Y opcode.
"""

import base_test
from registers import Reg, SREG

class LDD_Y_TestFail(base_test.TestFail): pass

class base_LDD_Y(base_test.opcode_test):
	"""Generic test case for testing LDD_Y opcode.

	LDD_Y - Load Indirect from data space to Register using index Y with
	displacement, q.

	Operation: Rd <- (Y+q)

	opcode is '10q0 qq0d dddd 1qqq' where 0 <= d <= 31, 0 <= q <= 63

	Only registers PC and Rd should be changed.
	"""
	def setup(self):
		# Set the register values
		self.setup_regs[self.Rd] = 0
		self.setup_regs[Reg.R28] = (self.Y & 0xff)
		self.setup_regs[Reg.R29] = (self.Y >> 8)

		# set up the val in memory
		self.mem_byte_write( self.Y + self.q, self.Vd )

		# Return the raw opcode
		op_q = ((self.q & 0x20) << 8) | ((self.q & 0x18) << 7) | (self.q & 0x3)
		return 0x8008 | (self.Rd << 4) | op_q

	def analyze_results(self):
		self.reg_changed.extend( [self.Rd] )
		
		# check that result is correct
		expect = self.Vd
		got = self.anal_regs[self.Rd]
		
		if expect != got:
			self.fail('LDD_Y: expect=%02x, got=%02x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class LDD_Y_r%02d_Y%04x_q%02x_v%02x_TestFail(LDD_Y_TestFail): pass

class test_LDD_Y_r%02d_Y%04x_q%02x_v%02x(base_LDD_Y):
	Rd = %d
	Y = 0x%x
	q = 0x%x
	Vd = 0x%x
	def fail(self,s):
		raise LDD_Y_r%02d_Y%04x_q%02x_v%02x_TestFail, s
"""

#
# automagically generate the test_LDD_Y_* class definitions.
#
code = ''
for d in range(0,32,4):
	for y in (0x10f, 0x1ff):
		for q in range(0,64,0x10):
			for v in (0xaa, 0x55):
				args = (d,y,q,v)*4
				code += template % args
exec code
