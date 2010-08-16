#! /usr/bin/env python
# -*- coding: utf-8 -*-
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
# $Id: base_test.py,v 1.1 2004/07/31 00:59:32 rivetwa Exp $
#

import array, struct
from avr_target import target
from registers import Reg, Addr

"""This module provides base classes for regression test cases.
"""

class TestFail:
	def __init__(self, reason):
		self.reason = reason
	def __repr__(self):
		return self.reason

class opcode_test:
	"""Base Class for testing opcodes.
	"""
	def __init__(self):
		self.target = target()

	def __repr__(self):
		return self.__name__
	
	def mem_byte_write(self, addr, val):
		self.target.write_sram(addr, 1, [val])

	def mem_byte_read(self, addr):
		return self.target.read_sram(addr, 1)[0]

	def prog_word_write(self, addr, val):
		self.target.write_flash(addr, 2, self.common_build_opcode(val))

	def run(self):
		"""Execute the test.

		If the test fails, an exception will be raised.
		"""
		self.common_setup()				# setup the test
		self.target.step()				# execute the opcode test
		self.common_analyze_results()	# do the analysis

	def common_setup(self):
		"""Perform common setup operations.

		All access to target for setup should be done here.

		This could be over-ridden by a more specific base class if needed.
		"""
		
		# Fetch all registers (might be able to get away with just creating an
		# array of zero'd out registers instead of going to target.		
		self.setup_regs = self.target.read_regs()

		# Run the test case setup and insert opcode into target.
		raw_opcode = self.setup()
		opcode = self.common_build_opcode(raw_opcode)
		self.target.write_flash(self.setup_regs[Reg.PC], len(opcode), opcode)

		# The test case should modify setup_regs as necessary so here we make sure
		# the target gets those changes
		self.target.write_regs(self.setup_regs)

	def common_build_opcode(self, raw_opcode):
		"""Build up the opcode array for a 16 bit opcode.
		"""
		return array.array( 'B', struct.pack('<H', raw_opcode ))

	def common_analyze_results(self):
		"""Perform common analysis operations.

		All access to target for setup should be done here.

		This could be over-ridden by a more specific base class if needed.
		"""
		
		# Most opcodes simply increment the PC, if not, then this should be
		# set and the test case will do the analysis itself.
		self.is_pc_checked = 0

		# Most of the registers don't change, the test case should test those
		# that changed and append the register number to this list.
		self.reg_changed = []
		
		# Fetch all registers: opcode operation may have changed some of them
		self.anal_regs = self.target.read_regs()

		# Run the test case specific analysis.
		self.analyze_results()

		# If test case didn't check PC itself, handle it here
		if not self.is_pc_checked:
			# check that PC was properly incremented
			expect = self.setup_regs[Reg.PC] + 2
			got = self.anal_regs[Reg.PC]
			if expect != got:
				raise TestFail, 'PC not incremented: expect=%x, got=%x' % (expect, got)

		# compare all regs except PC and those in reg_changed list
		for i in range(Reg.PC):
			if i in self.reg_changed:
				continue
			expect = self.setup_regs[i]
			got = self.anal_regs[i]
			if expect != got:
				raise TestFail, 'Register %d changed: expect=%x, got=%x' % (i, expect, got)

	def setup(self):
		"""Default setup method.

		This is automatically called to setup up any needed preconditions
		before running the test. The default does nothing thus if
		preconditions are required, the derived class must override this.
		"""
		raise TestFail, 'Default setup() method used'

	def analyze_result(self):
		"""Analyze the results of the execute() method.

		Automatically called by the run() method. The default is to force a
		failed test such that the writer of a test case will know that the
		derived class doesn't have a specific analyze_results() method.

		Raise a TestFail exception if a test fails with a reason for failure
		string as data.
		"""
		raise TestFail, 'Default analyze_results() method used'

##
## Big Hairy Note: Mixin's _must_ come beform the base class in multiple
## inheritance for the mixin to override what is in the base class. Inheritance
## is a left to right operation. For example, if foo and bar both have method
## gotcha(), then baz will get foo's version of gotcha() with this:
##   class baz( foo, bar ): pass
##

class opcode_32_mixin:
	"""Mixin Class for testing 32 bit opcodes.

	CALL, JMP, LDS, and STS are the only two word (32 bit) instructions.	
	"""
	def common_build_opcode(self, raw_opcode):
		"""Build up the opcode array for a 32 bit opcode from 2 raw 32 bit value.
		"""
		return array.array( 'B', struct.pack('<HH',
											 (raw_opcode >> 16) & 0xffff,
											 (raw_opcode & 0xffff)) )

class opcode_stack_mixin:
	"""Mixin Class for testing opcodes which perform stack operations.
	"""
	SP_val = 1020

	def common_setup(self):
		"""Initialize the stack and then call the base class common_setup.
		"""
		self.target.write_reg(Reg.SP, self.SP_val)
		
		opcode_test.common_setup(self)

	def setup_write_to_current_stack(self, val):
		# Since a push is a post-decrement operation and pop is pre-increment,
		# we need to use SP+1 here.
		# Also, note that this should only be used in setup.
		self.target.write_sram(self.SP_val+1, 1, [val])

	def setup_word_to_stack(self, val):
		# used by RET, RETI setup, since they pop at least a word
		self.target.write_sram(self.SP_val+1, 2, [(val & 0xff00)>>8, val & 0xff])

	def analyze_read_from_current_stack(self):
		return self.target.read_sram(self.SP_val, 1)[0]

class opcode_32_test(opcode_32_mixin, opcode_test):
	pass

class opcode_stack_test(opcode_stack_mixin, opcode_test):
	pass

class opcode_stack_32_test(opcode_32_mixin, opcode_stack_mixin, opcode_test):
	"""Base Class for testing 32 bit opcodes with stack operations.
	"""
	pass
