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
# $Id: test_LD_Y_incr.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the LD_Y_incr opcode.
"""

import base_test
from registers import Reg, SREG

class LD_Y_incr_TestFail(base_test.TestFail): pass

class base_LD_Y_incr(base_test.opcode_test):
	"""Generic test case for testing LD_Y_incr opcode.

	LD_Y_incr - Load Indirect from data space to Register using index Y and
	post increment Y.

	Operation: Rd <- (Y) then Y <- Y + 1

	opcode is '1001 000d dddd 1001' where 0 <= d <= 31 and d != {28,29}

	Only registers PC, R28, R29 and Rd should be changed.
	"""
	def setup(self):
		# Set the register values
		self.setup_regs[self.Rd] = 0
		self.setup_regs[Reg.R28] = (self.Y & 0xff)
		self.setup_regs[Reg.R29] = ((self.Y >> 8) & 0xff)

		# set up the val in memory (memory is read before Y is incremented,
		# thus we need to write to memory _at_ Y)
		self.mem_byte_write( self.Y, self.Vd )

		# Return the raw opcode
		return 0x9009 | (self.Rd << 4)

	def analyze_results(self):
		self.reg_changed.extend( [self.Rd, Reg.R28, Reg.R29] )
		
		# check that result is correct
		expect = self.Vd
		got = self.anal_regs[self.Rd]
		
		if expect != got:
			self.fail('LD_Y_incr: expect=%02x, got=%02x' % (expect, got))

		# check that Y was incremented
		expect = self.Y + 1
		got = (self.anal_regs[Reg.R28] & 0xff) | ((self.anal_regs[Reg.R29] << 8) & 0xff00)

		if expect != got:
			self.fail('LD_Y_incr Y not incr: expect=%04x, got=%04x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class LD_Y_incr_r%02d_Y%04x_v%02x_TestFail(LD_Y_incr_TestFail): pass

class test_LD_Y_incr_r%02d_Y%04x_v%02x(base_LD_Y_incr):
	Rd = %d
	Y = 0x%x
	Vd = 0x%x
	def fail(self,s):
		raise LD_Y_incr_r%02d_Y%04x_v%02x_TestFail, s
"""

#
# automagically generate the test_LD_Y_incr_rNN_vXX class definitions.
#
# Operation is undefined for d = 28 and d = 29.
#
code = ''
for d in range(0,28)+range(30,32):
	for y in (0x10f, 0x1ff):
		for v in (0xaa, 0x55):
			args = (d,y,v)*4
			code += template % args
exec code
