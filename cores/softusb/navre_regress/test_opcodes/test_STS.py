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
# $Id: test_STS.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the STS opcode.
"""

import base_test
from registers import Reg

class STS_TestFail(base_test.TestFail): pass

class base_STS(base_test.opcode_32_test):
	"""Generic test case for testing STS opcode.

	The derived class must provide the reg member and the fail method.

	STS - Store Direct to data space: copy the data from Rd to addr k (in data
	space)

	Operation: (k) <- Rd

	32-bit opcode: '1001 001d dddd 0000 kkkk kkkk kkkk kkkk' 0 <= k < 64K
	"""
	def setup(self):
		self.setup_regs[Reg.PC] = 0xff * 2
		self.setup_regs[self.Rd] = self.v

		op = 0x9200 | (self.Rd << 4)
		return ( (op << 16) | (self.k & 0xffff) )

	def analyze_results(self):
		self.is_pc_checked = 1
		
		expect = self.setup_regs[Reg.PC] + 4
		got = self.anal_regs[Reg.PC]
		
		if expect != got:
			self.fail('STS pc check: expect=%x, got=%x' % (expect, got))

		expect = self.v
		got = self.mem_byte_read(self.k)

		if expect != got:
			self.fail('STS register: expect=%x, got=%x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class STS_r%02d_k%04x_v%02x_TestFail(STS_TestFail): pass

class test_STS_r%02d_k%04x_v%02x(base_STS):
	Rd = %d
	k = 0x%x
	v = 0x%x
	def fail(self,s):
		raise STS_r%02d_k%04x_v%02x_TestFail, s
"""

#
# automagically generate the test_STS_* class definitions
#
code = ''
for d in range(0,32):
	for k in (0x10f, 0x1ff):
		for v in (0xaa, 0x55):
			args = (d,k,v)*4
			code += template % args
exec code
