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
# $Id: test_MOVW.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the MOVW opcode.
"""

import base_test
from registers import Reg

class MOVW_TestFail(base_test.TestFail): pass

class base_MOVW(base_test.opcode_test):
	"""Generic test case for testing MOVW opcode.

	The derived class must provide the reg member and the fail method.

	MOVW - Copy Register Word
	"""
	def setup(self):
		self.setup_regs[self.Rd]   = 0x00
		self.setup_regs[self.Rd+1] = 0x00
		self.setup_regs[self.Rr]   = 0xa5
		self.setup_regs[self.Rr+1] = 0x5a

		# opcode is '0000 0001 dddd rrrr' where d and r are Rd/2 and Rr/2
		return 0x0100 | ((self.Rd/2) << 4) | ((self.Rr/2) & 0xf)

	def analyze_results(self):
		self.reg_changed.extend( [self.Rd,self.Rd+1] )
		if self.anal_regs[self.Rd] != 0xa5 or self.anal_regs[self.Rd+1] != 0x5a:
			self.fail('MOVW failed: expect=a55a, got=%02x%02x' % (
				self.anal_regs[self.Rd], self.anal_regs[self.Rd+1]))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class MOVW_r%02d_r%02d_TestFail(MOVW_TestFail): pass

class test_MOVW_r%02d_r%02d(base_MOVW):
	Rd = %d
	Rr = %d
	def fail(self,s):
		raise MOVW_r%02d_r%02d_TestFail, s
"""

#
# automagically generate the test_MOVW_* class definitions
#
code = ''
for d in range(0,32,4):
	for r in range(2,32,4):
		args = (d,r)*4
		code += template % args
exec code
