# -*- coding: utf-8 -*-

FLASH_SIZE = 8192
SRAM_SIZE = 1024

class target:
	def __init__(self):
		self.regs = [0]*35		# unit: register (8-bit except SP and PC)
		self.flash = [0]*FLASH_SIZE	# unit: byte
		self.sram = [0]*SRAM_SIZE	# unit: byte

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
		f = open("flash.rom", "w")
		for i in range(0, FLASH_SIZE, 2):
			f.write("%02x%02x\n" % (self.flash[i+1], self.flash[i]))
		f.close()
		f = open("sram.rom", "w")
		for i in range(0, SRAM_SIZE):
			f.write("%02x\n" % (self.sram[i]))
		f.close()
		f = open("gpr.rom", "w")
		for i in range(0, 24):
			f.write("%02x\n" % (self.regs[i]))
		f.close()
		f = open("spr.rom", "w")
		for i in range(24, 33):
			f.write("%02x\n" % (self.regs[i]))
		for i in range(33, 35):
			f.write("%02x\n" % ((self.regs[i] & 0xff00) >> 8))
			f.write("%02x\n" % (self.regs[i] & 0x00ff))
		f.close()
