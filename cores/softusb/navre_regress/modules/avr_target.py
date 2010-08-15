# -*- coding: utf-8 -*-

class target:
	def read_regs(self):
		return range(35)

	def write_regs(self, regs):
		pass

	def write_reg(self, reg, val):
		pass

	def write_reg(self, reg, val):
		pass

	def read_flash(self, addr, _len):
		return 0
	
	def write_flash(self, addr, _len, buf):
		pass
	
	def read_sram(self, addr, _len):
		return [0]

	def write_sram(self, addr, _len, buf):
		pass
	
	def step(self):
		pass

