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
# $Id: test_ST_Z_incr.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the ST_Z_incr opcode.
"""

import base_test
from registers import Reg, SREG

class ST_Z_incr_TestFail(base_test.TestFail): pass

class base_ST_Z_incr(base_test.opcode_test):
	"""Generic test case for testing ST_Z_incr opcode.

	ST_Z_incr - Store Indirect to data space from Register using index Z with
	post-increment.

	Operation: (Z) <- Rd then Z <- Z + 1

	opcode is '1001 001d dddd 0001' where 0 <= d <= 31

	Only registers PC should be changed.
	"""
	def setup(self):
		# Set the register values
		self.setup_regs[self.Rd] = self.Vd
		self.setup_regs[Reg.R30] = (self.Z & 0xff)
		self.setup_regs[Reg.R31] = (self.Z >> 8)

		# Return the raw opcode
		return 0x9201 | (self.Rd << 4)

	def analyze_results(self):
		self.reg_changed.extend( [Reg.R30, Reg.R31] )

		# check that result is correct
		expect = self.Vd
		got = self.mem_byte_read( self.Z )
		
		if expect != got:
			self.fail('ST_Z_incr: expect=%02x, got=%02x' % (expect, got))

		# check that Z was incremented
		expect = self.Z + 1
		got = (self.anal_regs[Reg.R30] & 0xff) | ((self.anal_regs[Reg.R31] << 8) & 0xff00)

		if expect != got:
			self.fail('LD_Z_incr Z not incr: expect=%04x, got=%04x' % (expect, got))
#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class ST_Z_incr_r%02d_Z%04x_v%02x_TestFail(ST_Z_incr_TestFail): pass

class test_ST_Z_incr_r%02d_Z%04x_v%02x(base_ST_Z_incr):
	Rd = %d
	Z = 0x%x
	Vd = 0x%x
	def fail(self,s):
		raise ST_Z_incr_r%02d_Z%04x_v%02x_TestFail, s
"""

#
# automagically generate the test_ST_Z_incr_* class definitions.
#
# Operation is undefined for d = 30 and d = 31.
#
code = ''
for d in range(0,30):
	for x in (0x10f, 0x1ff):
		for v in (0xaa, 0x55):
			args = (d,x,v)*4
			code += template % args
exec code
