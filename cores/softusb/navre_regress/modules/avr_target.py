# -*- coding: utf-8 -*-

class target:
	def __init__(self):
		self.regs = [0]*35	# unit: register (8-bit except SP and PC)
		self.flash = [0]*8192	# unit: byte
		self.sram = [0]*1024	# unit: byte

	def read_regs(self):
		return self.regs

	def write_regs(self, regs):
		self.regs = regs

	def write_reg(self, reg, val):
		self.regs[reg] = val

	def write_flash(self, addr, _len, buf):
		for i in range(0, _len):
			self.flash[addr+i] = buf[i]
	
	def read_sram(self, addr, _len):
		return self.sram[addr:addr+_len]

	def write_sram(self, addr, _len, buf):
		for i in range(0, _len):
			self.sram[addr+i] = buf[i]
	
	def step(self):
		print "*** STEP"
