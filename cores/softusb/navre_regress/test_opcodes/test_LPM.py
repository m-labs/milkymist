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
# $Id: test_LPM.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the LPM opcode.
"""

import base_test
from registers import Reg, SREG

class LPM_TestFail(base_test.TestFail): pass

class base_LPM(base_test.opcode_test):
	"""Generic test case for testing LPM opcode.

	LPM - Load Program Memory

	Operation: R0 <- (Z)

	opcode is '1001 0101 1100 1000'

	Only registers PC and R00 should be changed.
	"""
	def setup(self):
		# Set the register values
		self.setup_regs[Reg.R00] = 0
		self.setup_regs[Reg.R30] = (self.Z & 0xff)
		self.setup_regs[Reg.R31] = (self.Z >> 8)

		# set up the val in memory
		self.prog_word_write( self.Z & 0xfffe, 0xaa55 )

		# Return the raw opcode
		return 0x95C8

	def analyze_results(self):
		self.reg_changed.extend( [Reg.R00] )
		
		# check that result is correct
		if self.Z & 0x1:
			expect = 0xaa
		else:
			expect = 0x55

		got = self.anal_regs[Reg.R00]
		
		if expect != got:
			self.fail('LPM: expect=%02x, got=%02x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class LPM_Z%04x_TestFail(LPM_TestFail): pass

class test_LPM_Z%04x(base_LPM):
	Z = 0x%x
	def fail(self,s):
		raise LPM_Z%04x_TestFail, s
"""

#
# automagically generate the test_LPM_* class definitions.
#
code = ''
for z in (0x10, 0x11, 0x100, 0x101):
	args = (z,)*4
	code += template % args
exec code
