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
# $Id: test_CALL.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the CALL opcode.
"""

import base_test
from registers import Reg

class CALL_TestFail(base_test.TestFail): pass

class base_CALL(base_test.opcode_stack_32_test):
	"""Generic test case for testing CALL opcode.

	The derived class must provide the reg member and the fail method.

	CALL - Relative call to subroutine

	  PC <- k
	  STACK <- PC + 2
	  
	  SP <- SP - 2         __or__         SP <- SP - 3
	  (2 bytes, 16 bit PC)                (3 bytes, 22 bit PC)
	  
	opcode is '1001 010k kkkk 111k kkkk kkkk kkkk kkkk'  0 <= k < 4M
	"""
	def setup(self):
		self.setup_regs[Reg.PC] = 0xff * 2

		tmp = self.k >> 16 & 0x3f
		op = 0x940e | (tmp << 3) & 0x1f0 | tmp & 0x1
		op =  (op << 16 | self.k & 0xffff)
		#print 'setting up op: %x' %(op)
		return op

	def analyze_results(self):
		self.reg_changed.append( Reg.SP )
		self.is_pc_checked = 1

		expect = self.k
		got = self.anal_regs[Reg.PC] / 2

		if expect != got:
			self.fail('CALL failed: expect=%x, got=%x' % (expect, got))

		sp_expect = self.setup_regs[Reg.SP] - 2 # 16 bit PC
		sp_got    = self.anal_regs[Reg.SP]

		if sp_got != sp_expect:
			self.fail('CALL stack push failed: expect=%x, got=%x' % (
				sp_expect, sp_got ))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class CALL_%06x_TestFail(CALL_TestFail): pass

class test_CALL_%06x(base_CALL):
	k = 0x%x
	def fail(self,s):
		raise CALL_%06x_TestFail, s
"""

#
# automagically generate the test_CALL_* class definitions
#
# FIXME: TRoth 2002-02-22: Really need to check jumps which wrap around the
# ends of flash memory. Will need to know the size of the device's flash space
# to do that though.
#
code = ''
for k in (0x100, 0x3ff):
	code += template % ((k & 0xffffff), (k & 0xffffff), k, (k & 0xffffff))
exec code
