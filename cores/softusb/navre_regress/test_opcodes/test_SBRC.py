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
# $Id: test_SBRC.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the SBRC opcode.
"""

import base_test
from registers import Reg

class SBRC_TestFail(base_test.TestFail): pass

class base_SBRC(base_test.opcode_test):
	"""Generic test case for testing SBRC opcode.

	The derived class must provide the reg member and the fail method.

	SBRC - Skip if Bit in Register is Cleared
	opcode is '1111 110d dddd 0bbb'
	"""
	def setup(self):
		self.setup_regs[self.Rd] = self.v	
		self.setup_regs[Reg.PC] = 0xff * 2

		# Need to make sure the PC+2 is a real insn
		if self.ni == 16:
			# just use a nop (0000 0000 0000 0000)
			next_op = 0x0000
		else:
			# use high byte of LDS (1001 000d dddd 0000) (d=0)
			next_op = 0x9000

		self.prog_word_write(self.setup_regs[Reg.PC]+2, next_op)

		return 0xFC00 | (self.Rd << 4) | (self.b & 0x7)

	def analyze_results(self):
		self.is_pc_checked = 1

		if self.v == 0:
			if self.ni == 16:
				expect = self.setup_regs[Reg.PC]/2 + 2
			else:
				expect = self.setup_regs[Reg.PC]/2 + 3
		else:
			expect = self.setup_regs[Reg.PC]/2 + 1
		
		got = self.anal_regs[Reg.PC] / 2
		
		if expect != got:
			self.fail('SBRC failed: expect=%x, got=%x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class SBRC_r%02d_b%d_v%02x_ni%d_TestFail(SBRC_TestFail): pass

class test_SBRC_r%02d_b%d_v%02x_ni%d(base_SBRC):
	Rd = %d
	b = %d
	v = %d
	ni = %d
	def fail(self,s):
		raise SBRC_r%02d_b%d_v%02x_ni%d_TestFail, s
"""

#
# automagically generate the test_SBRC_* class definitions
#
code = ''
for d in range(32):
	for b in range(8):
		for v in (0,0xff):
			for ni in (16,32): # is next insn 16 or 32 bits
				args = (d,b,v,ni)*4
				code += template % args
exec code
