# -*- coding: utf-8 -*-

import subprocess
import copy

FLASH_SIZE = 8192
SRAM_SIZE = 1024

class target:
	def __init__(self):
		self.regs = [0]*35		# unit: register (8-bit except SP and PC)
		self.flash = [0]*FLASH_SIZE	# unit: byte
		self.sram = [0]*SRAM_SIZE	# unit: byte

	def read_regs(self):
		return copy.deepcopy(self.regs)

	def write_regs(self, regs):
		self.regs = copy.deepcopy(regs)

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

		p = subprocess.Popen(["cver", "-q", "+define+REGRESS", "tb_regress.v", "../rtl/softusb_navre.v"],  stdout=subprocess.PIPE)
		(stdoutdata, stderrdata) = p.communicate()
		p.wait()

		mode = 0
		for line in stdoutdata.split('\n'):
			if line == "DUMP REGISTERS":
				mode = 1
				index = 0
			elif line == "DUMP DMEM":
				mode = 2
				index = 0
			elif line != "":
				if mode == 1:
					if index < 32:
						self.regs[index] = int(line, 16)
					elif index == 33:
						self.regs[33] = int(line, 16) << 8
					elif index == 34:
						self.regs[33] = self.regs[33] | int(line, 16)
					elif index == 35:
						self.regs[34] = int(line, 16) << 8
					elif index == 36:
						self.regs[34] = self.regs[34] | int(line, 16)
					index = index + 1
				elif mode == 2:
					self.sram[index] = int(line, 16)
					index = index + 1
