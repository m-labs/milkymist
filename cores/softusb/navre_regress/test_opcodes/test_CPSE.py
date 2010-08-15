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
# $Id: test_CPSE.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the CPSE opcode.
"""

import base_test
from registers import Reg

class CPSE_TestFail(base_test.TestFail): pass

class base_CPSE(base_test.opcode_test):
	"""Generic test case for testing CPSE opcode.

	The derived class must provide the reg member and the fail method.

	CPSE - Compare, Skip if Equal
	opcode is '0001 11rd dddd rrrr'
	"""
	def setup(self):
		self.setup_regs[self.Rd] = self.vd
		self.setup_regs[self.Rr] = self.vr

		self.setup_regs[Reg.PC] = 0xff * 2

		# Need to make sure the PC+2 is a real insn
		if self.ni == 16:
			# just use a nop (0000 0000 0000 0000)
			next_op = 0x0000
		else:
			# use high byte of LDS (1001 000d dddd 0000) (d=0)
			next_op = 0x9000

		self.prog_word_write(self.setup_regs[Reg.PC]+2, next_op)

		return 0x1000 | (self.Rd << 4) | (self.Rr & 0xf) | ((self.Rr & 0x10) << 5)

	def analyze_results(self):
		self.is_pc_checked = 1

		if self.vd == self.vr:
			if self.ni == 16:
				expect = self.setup_regs[Reg.PC]/2 + 2
			else:
				expect = self.setup_regs[Reg.PC]/2 + 3
		else:
			expect = self.setup_regs[Reg.PC]/2 + 1
		
		got = self.anal_regs[Reg.PC] / 2
		
		if expect != got:
			self.fail('CPSE failed: expect=%x, got=%x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class CPSE_rd%02d_vd%02x_rr%02d_vr%02x_ni%d_TestFail(CPSE_TestFail): pass

class test_CPSE_rd%02d_vd%02x_rr%02d_vr%02x_ni%d(base_CPSE):
	Rd = %d
	vd = 0x%x
	Rr = %d
	vr = 0x%x
	ni = %d
	def fail(self,s):
		raise CPSE_rd%02d_vd%02x_rr%02d_vr%02x_ni%d_TestFail, s
"""

vals = (
( 0xaa, 0x55 ),
( 0xa0, 0xa0 ),
)

#
# automagically generate the test_CPSE_* class definitions
#
code = ''
step = 4
for d in range(0,32,step):
	for r in range(1,32,step):
		for vr,vd in vals:
			for ni in (16,32): # is next insn 16 or 32 bits
				args = (d,vd,r,vr,ni)*4
				code += template % args

# Special case when Rd==Rr, set Vd==Vr
for d in range(0,32,step):
	for vr,vd in vals:
		for ni in (16,32): # is next insn 16 or 32 bits
			args = (d,vd,d,vd,ni)*4
			code += template % args
exec code
