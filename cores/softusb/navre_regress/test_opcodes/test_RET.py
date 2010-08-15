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
# $Id: test_RET.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the RET opcode.
"""

import base_test
from registers import Reg

class RET_TestFail(base_test.TestFail): pass

class base_RET(base_test.opcode_stack_test):
	"""Generic test case for testing RET opcode.

	The derived class must provide the reg member and the fail method.
	
	description: RET - return from called function the return address
	             is loaded from the stack
	syntax:      RET 
	
	opcode is '1001 0101 0000 1000'
	"""
	def setup(self):
		# set the pc to a different position
		self.setup_regs[Reg.PC] = self.old_pc * 2

		# put the value on the stack
		self.setup_word_to_stack(self.new_pc)
		return 0x9508

	def analyze_results(self):
		self.is_pc_checked = 1
		self.reg_changed.extend( [ Reg.SP ] )

		# check that SP changed correctly
		expect = self.setup_regs[Reg.SP] + 2
		got    = self.anal_regs[Reg.SP]

		if got != expect:
			self.fail('RET stack pop failed! SP: expect=%x, got=%x' % (
				expect, got ))

		# check that PC changed correctly
		expect = self.new_pc
		got = self.anal_regs[Reg.PC]/2

		if got != expect:
			self.fail('RET operation failed! PC: expect=%x, got=%x' % (
				expect, got ))

#
# Template code for test case.
# The fail method will raise a test specific exception.
# 
template = """class RET_new_%06x_old_%06x_TestFail(RET_TestFail): pass

class test_RET_old_%06x_new_%06x(base_RET):
	old_pc = %d
	new_pc = %d
	def fail(self,s):
		raise RET_new_%06x_old_%06x_TestFail, s
"""

#
# automagically generate the test_RET_* class definitions
#
code = ''

for old_pc in (0,255,256,(8*1024/2-1)):
	for new_pc in (0,1,2,3,255,256,(8*1024/2-1)):
		args = (old_pc,new_pc)*4
		code += template % args
exec code






