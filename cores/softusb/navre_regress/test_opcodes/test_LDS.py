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
# $Id: test_LDS.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the LDS opcode.
"""

import base_test
from registers import Reg

class LDS_TestFail(base_test.TestFail): pass

class base_LDS(base_test.opcode_32_test):
	"""Generic test case for testing LDS opcode.

	The derived class must provide the reg member and the fail method.

	LDS - Load Direct from data space: copy the data pointed to by k (in data
	space) in to Rd

	Operation: Rd <- (k)

	32-bit opcode: '1001 000d dddd 0000 kkkk kkkk kkkk kkkk' 0 <= k < 64K
	"""
	def setup(self):
		self.setup_regs[Reg.PC] = 0xff * 2
		self.setup_regs[self.Rd] = 0x0

		self.mem_byte_write(self.k,self.v)

		op = 0x9000 | (self.Rd << 4)
		return ( (op << 16) | (self.k & 0xffff) )

	def analyze_results(self):
		self.reg_changed.extend( [self.Rd] )
		self.is_pc_checked = 1
		
		expect = self.setup_regs[Reg.PC] + 4
		got = self.anal_regs[Reg.PC]
		
		if expect != got:
			self.fail('LDS pc check: expect=%x, got=%x' % (expect, got))

		expect = self.v
		got = self.anal_regs[self.Rd]

		if expect != got:
			self.fail('LDS register: expect=%x, got=%x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class LDS_r%02d_k%04x_v%02x_TestFail(LDS_TestFail): pass

class test_LDS_r%02d_k%04x_v%02x(base_LDS):
	Rd = %d
	k = 0x%x
	v = 0x%x
	def fail(self,s):
		raise LDS_r%02d_k%04x_v%02x_TestFail, s
"""

#
# automagically generate the test_LDS_* class definitions
#
code = ''
for d in range(0,32):
	for k in (0x10f, 0x1ff):
		for v in (0xaa, 0x55):
			args = (d,k,v)*4
			code += template % args
exec code
