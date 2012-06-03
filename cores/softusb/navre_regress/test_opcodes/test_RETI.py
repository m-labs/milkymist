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
# $Id: test_RETI.py,v 0.5 josef
#

"""Test the RETI opcode.
"""

import base_test
from registers import Reg, SREG

class RETI_TestFail(base_test.TestFail): pass

class base_RETI(base_test.opcode_stack_test):
	"""Generic test case for testing RETI opcode.

	The derived class must provide the reg member and the fail method.
	
	description: RETI - return from interrupt routine the return address
	             is loaded from the stack and set the global interrupt flag
	syntax:      RETI
	
	opcode is '1001 0101 0001 1000'
	"""
	def setup(self):
		# put the value on the stack
		self.setup_word_to_stack(self.new_pc)

		# zero the SREG
		self.setup_regs[Reg.SREG] = 0

		return 0x9518

	def analyze_results(self):
		self.is_pc_checked = 1
		self.reg_changed.extend( [ Reg.SP, Reg.SREG ] )

		# check that SP changed correctly
		expect = self.setup_regs[Reg.SP] + 2
		got    = self.anal_regs[Reg.SP]

		if got != expect:
			self.fail('RETI stack pop failed! SP: expect=%x, got=%x' % (
				expect, got ))

		# check that PC changed correctly
		expect = self.new_pc
		got = self.anal_regs[Reg.PC]/2

		if got != expect:
			self.fail('RETI operation failed! PC: expect=%x, got=%x' % (
				expect, got ))

		# check no SREG flag changed
		expect =0x1 << SREG.I
		got = self.anal_regs[Reg.SREG]

		if got != expect:
			self.fail('SREG incorrectly updated: expect=%02x, got=%02x' %(expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#

template = """class RETI_new_%06x_old_%06x_TestFail(RETI_TestFail): pass

class test_RETI_old_%06x_new_%06x(base_RETI):
	old_pc = 0x%06x
	new_pc = 0x%06x
	def fail(self,s):
		raise RETI_new_%06x_old_%06x_TestFail, s
"""

#
# automagically generate the test_RETI_* class definitions
#
code = ''

for old_pc in (0,255,256,(8*1024/2-1)):
	for new_pc in (0,1,2,3,255,256,(8*1024/2-1)):
		args = (old_pc,new_pc)*4
		code += template % args
exec code
