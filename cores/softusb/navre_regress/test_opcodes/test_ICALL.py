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
# $Id: test_ICALL.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the ICALL opcode.
"""

import base_test
from registers import Reg

class ICALL_TestFail(base_test.TestFail): pass

class base_ICALL(base_test.opcode_stack_test):
	"""Generic test case for testing ICALL opcode.

	The derived class must provide the reg member and the fail method.

	ICALL - Indirect call to subroutine

	  PC(15:0) <- Z(15:0)
	  STACK <- PC + 1
	  
	  SP <- SP - 2         __or__         SP <- SP - 3
	  (2 bytes, 16 bit PC)                (3 bytes, 22 bit PC)
	  
	opcode is '1001 0101 0000 1001'
	"""
	def setup(self):
		# setup PC
		self.setup_regs[Reg.PC] = 0xff * 2

		# setup Z register (Z = R31:R30)
		self.setup_regs[Reg.R30] = self.k & 0xff
		self.setup_regs[Reg.R31] = self.k >> 8 & 0xff

		return 0x9509

	def analyze_results(self):
		self.reg_changed.append( Reg.SP )
		self.is_pc_checked = 1

		expect = self.k

		got = self.anal_regs[Reg.PC] / 2
		
		if expect != got:
			self.fail('ICALL failed: expect=%x, got=%x' % (expect, got))

		expect = self.setup_regs[Reg.SP] - 2 # 16 bit PC
		got    = self.anal_regs[Reg.SP]
		
		if got != expect:
			self.fail('ICALL stack push failed: expect=%04x, got=%04x' % (
				expect, got ))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class ICALL_%04x_TestFail(ICALL_TestFail): pass

class test_ICALL_%04x(base_ICALL):
	k = 0x%x
	def fail(self,s):
		raise ICALL_%04x_TestFail, s
"""

#
# automagically generate the test_ICALL_* class definitions
#
code = ''
for k in (0x100,0x3ff):
	code += template % ((k & 0xffff), (k & 0xffff), k, (k & 0xffff))
exec code
