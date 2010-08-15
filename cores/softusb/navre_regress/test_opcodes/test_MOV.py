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
# $Id: test_MOV.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the MOV opcode.
"""

import base_test
from registers import Reg

class MOV_TestFail(base_test.TestFail): pass

class base_MOV(base_test.opcode_test):
	"""Generic test case for testing MOV opcode.

	The derived class must provide the reg member and the fail method.

	MOV - Copy Register
	"""
	def setup(self):
		self.setup_regs[self.Rd] = 0x00
		self.setup_regs[self.Rr] = 0xa5

		# opcode is '0010 11rd dddd rrrr' where d is reg number (0-31)
		return 0x2C00 | (self.Rd << 4) | ((self.Rr & 0x10) << 5) | (self.Rr & 0xf)

	def analyze_results(self):
		self.reg_changed.append(self.Rd)
		if self.anal_regs[self.Rd] != 0xa5:
			self.fail('MOV failed: expect=a5, got=%02x' % (self.anal_regs[self.Rd]))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class MOV_r%02d_r%02d_TestFail(MOV_TestFail): pass

class test_MOV_r%02d_r%02d(base_MOV):
	Rd = %d
	Rr = %d
	def fail(self,s):
		raise MOV_r%02d_r%02d_TestFail, s
"""

#
# automagically generate the test_MOV_* class definitions
#
code = ''
for d in range(0,32,8):
	for r in range(1,32,8):
		args = (d,r)*4
		code += template % args
exec code
