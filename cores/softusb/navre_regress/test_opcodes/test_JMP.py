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
# $Id: test_JMP.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the JMP opcode.
"""

import base_test
from registers import Reg

class JMP_TestFail(base_test.TestFail): pass

class base_JMP(base_test.opcode_32_test):
	"""Generic test case for testing JMP opcode.

	The derived class must provide the reg member and the fail method.

	JMP - Relative Jump [PC <- k]
	opcode is '1001 010k kkkk 110k kkkk kkkk kkkk kkkk'  0 <= k < 4M
	"""
	def setup(self):
		self.setup_regs[Reg.PC] = 0xff * 2

		tmp = self.k >> 16
		op = 0x940c | (tmp << 3) & 0x1f0 | tmp & 0x1 
		return (op << 16 | self.k & 0xffff)

	def analyze_results(self):
		self.is_pc_checked = 1
		
		expect = self.k

		got = self.anal_regs[Reg.PC] / 2
		
		if expect != got:
			self.fail('JMP failed: expect=%x, got=%x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class JMP_%06x_TestFail(JMP_TestFail): pass

class test_JMP_%06x(base_JMP):
	k = 0x%x
	def fail(self,s):
		raise JMP_%06x_TestFail, s
"""

#
# automagically generate the test_JMP_* class definitions
#
code = ''
for k in (0x100, 0x3ff):
	code += template % (k, k, k, k)
exec code
