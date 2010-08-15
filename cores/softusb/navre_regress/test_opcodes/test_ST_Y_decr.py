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
# $Id: test_ST_Y_decr.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the ST_Y_decr opcode.
"""

import base_test
from registers import Reg, SREG

class ST_Y_decr_TestFail(base_test.TestFail): pass

class base_ST_Y_decr(base_test.opcode_test):
	"""Generic test case for testing ST_Y_decr opcode.

	ST_Y_decr - Store Indirect to data space from Register using index Y with
	pre-decrement.

	Operation: Y <- Y - 1 then (Y) <- Rd 

	opcode is '1001 001d dddd 1010' where 0 <= d <= 31

	Only registers PC, R28 and R29 should be changed.
	"""
	def setup(self):
		# Set the register values
		self.setup_regs[self.Rd] = self.Vd
		self.setup_regs[Reg.R28] = (self.Y & 0xff)
		self.setup_regs[Reg.R29] = (self.Y >> 8)

		# Return the raw opcode
		return 0x920A | (self.Rd << 4)

	def analyze_results(self):
		self.reg_changed.extend( [Reg.R28, Reg.R29] )

		# check that result is correct
		expect = self.Vd
		# must account for pre-decrement
		got = self.mem_byte_read( self.Y - 1 )
		
		if expect != got:
			self.fail('ST_Y_decr: expect=%02x, got=%02x' % (expect, got))

		# check that Y was decremented
		expect = self.Y - 1
		got = (self.anal_regs[Reg.R28] & 0xff) | ((self.anal_regs[Reg.R29] << 8) & 0xff00)

		if expect != got:
			self.fail('LD_Y_decr Y not decr: expect=%04x, got=%04x' % (expect, got))
#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class ST_Y_decr_r%02d_Y%04x_v%02x_TestFail(ST_Y_decr_TestFail): pass

class test_ST_Y_decr_r%02d_Y%04x_v%02x(base_ST_Y_decr):
	Rd = %d
	Y = 0x%x
	Vd = 0x%x
	def fail(self,s):
		raise ST_Y_decr_r%02d_Y%04x_v%02x_TestFail, s
"""

#
# automagically generate the test_ST_Y_decr_* class definitions.
#
# Operation is undefined for d = 28 and d = 29.
#
code = ''
for d in range(0,28)+range(30,32):
	for x in (0x10f, 0x1ff):
		for v in (0xaa, 0x55):
			args = (d,x,v)*4
			code += template % args
exec code
