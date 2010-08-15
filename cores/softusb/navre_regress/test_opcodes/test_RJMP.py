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
# $Id: test_RJMP.py,v 1.1 2004/07/31 00:59:11 rivetwa Exp $
#

"""Test the RJMP opcode.
"""

import base_test
from registers import Reg

class RJMP_TestFail(base_test.TestFail): pass

class base_RJMP(base_test.opcode_test):
  """Generic test case for testing RJMP opcode.

  The derived class must provide the reg member and the fail method.

  RJMP - Relative Jump [PC <- PC + k + 1]
  opcode is '1100 kkkk kkkk kkkk'  -2K <= k < 2K
  """
  def setup(self):
    self.setup_regs[Reg.PC] = 0xff * 2
    return 0xC000 | (self.k & 0x0fff)

  def analyze_results(self):
    self.is_pc_checked = 1
    
    if (self.k & 0x800) == 0x800:
      # jump target is negative!
      expect = self.setup_regs[Reg.PC]/2 - (0x1000 - self.k) + 1
    else:
      # jump target is positive
      expect = self.setup_regs[Reg.PC]/2 + self.k + 1

    got = self.anal_regs[Reg.PC] / 2
    
    if expect != got:
      self.fail('RJMP failed: expect=%x, got=%x' % (expect, got))

#
# Template code for test case.
# The fail method will raise a test specific exception.
#
template = """
class RJMP_%03x_TestFail(RJMP_TestFail): pass

class test_RJMP_%03x(base_RJMP):
  k = 0x%x
  def fail(self,s):
    raise RJMP_%03x_TestFail, s
"""

#
# automagically generate the test_RJMP_* class definitions
#
# FIXME: TRoth 2002-02-22: Really need to check jumps which wrap around the
# ends of flash memory. Will need to know the size of the device's flash space
# to do that though.
#
code = ''
for k in (-100,100):
  code += template % ((k & 0xfff), (k & 0xfff), (k & 0xfff), (k & 0xfff))
exec code
