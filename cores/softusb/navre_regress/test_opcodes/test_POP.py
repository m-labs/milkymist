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
# $Id: test_POP.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the POP opcode.
"""

import base_test
from registers import Reg

class POP_TestFail(base_test.TestFail): pass

class base_POP(base_test.opcode_stack_test):
	"""Generic test case for testing POP opcode.

	The derived class must provide the reg member and the fail method.

	POP - Pop a register from the stack

	  Rd <- STACK

	  PC <- PC + 1
	  SP <- SP + 1

	opcode is '1001 000d dddd 1111'
	"""
	def setup(self):
		# zero out the register is question
		self.setup_regs[self.Rd] = 0

		# put the value on the stack
		self.setup_write_to_current_stack(self.k)

		return 0x900f | self.Rd << 4

	def analyze_results(self):
		self.reg_changed.extend( [ self.Rd, Reg.SP ] )

		# check that SP changed correctly
		expect = self.setup_regs[Reg.SP] + 1
		got    = self.anal_regs[Reg.SP]
		
		if got != expect:
			self.fail('POP stack push failed: expect=%04x, got=%04x' % (
				expect, got ))

		# check that Rd now has k
		expect = self.k
		got = self.anal_regs[self.Rd]

		if got != expect:
			self.fail('POP operation failed: expect=%02x, got=%02x' % (
				expect, got ))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """class POP_r%02d_%02x_TestFail(POP_TestFail): pass

class test_POP_r%02d_%02x(base_POP):
	Rd = %d
	k = 0x%x
	def fail(self,s):
		raise POP_r%02d_%02x_TestFail, s
"""

#
# automagically generate the test_POP_* class definitions
#
code = ''
for rd in range(32):
	for k in (0x55,0xaa):
		args = (rd,k)*4
		code += template % args
exec code
