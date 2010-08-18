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
# $Id: regress.py.in,v 1.1 2004/07/31 00:58:05 rivetwa Exp $
#

# # regress/regress.py.  Generated from regress.py.in by configure.

import os, os.path, sys, fnmatch, glob

# Check the python version
_v = sys.version_info
_ver = (int(_v[0]) << 16) + (int(_v[1]) << 8) + int(_v[2])
if _ver < 0x020101:
  sys.write('You need python >= 2.1.1 to run this program.\n')
  sys.write('Your python version is:\n%s\n' %(sys.version))
  sys.exit(1)

# Add modules dir to module search path
sys.path.append('modules')

import base_test

"""Main regression test driver program.

Test cases are organised into three levels: directories -> modules -> classes.
Directories are the most generic and classes are the most specific.

This program will search the current directory for subdirectories with names
matching 'test_*'. Each matching subdirectory will be searched for python
modules with names matching test_*.py. Each module will be loaded and the
attributes searched for classes with names beginning with 'test_'. Each class
will perform a single test and if the test fails, an exception derived from
base_test.TestFail is raised to indicate that the test has failed.

There can be many matches are each level.

"""

EXIT_STATUS_PASS = 0
EXIT_STATUS_FAIL = 1

def run_tests(tdir=None, tmodule=None, tname=None):
  result = EXIT_STATUS_PASS

  num_tests  = 0
  num_passes = 0
  num_fails  = 0

  start_time = sum(os.times()[:2])

  if tdir is None:
    test_dirs = glob.glob('test_*')
  else:
    if tdir[:5] != 'test_':
      tdir = 'test_'+tdir
    test_dirs = [tdir]

  for test_dir in test_dirs:
    if tmodule is None:
      try:
        test_modules = os.listdir(test_dir)
      except OSError:
        # problem getting dir listing, go to next dir
        continue
    else:
      if tmodule[:5] != 'test_':
        tmodule = 'test_'+tmodule
      if tmodule[-3:] != '.py':
        tmodule += '.py'
      test_modules = [tmodule]

    print '='*8 + ' running tests in %s directory' % (test_dir)
    # add tests dir to module search patch
    sys.path.append(test_dir)

    # Loop through all files in test dir
    for file in test_modules:
      # skip files which are not test modules (test modules are 'test_*.py')
      if not fnmatch.fnmatch(file, 'test_*.py'):
        continue

      # get test module name by stripping off .py from file name
      test_module_name = file[:-3]
      print '-'*4 + ' loading tests from %s module' %(test_module_name)
      test_module = __import__(test_module_name)

      if tname is None:
        test_names = dir(test_module)
      else:
        if tname[:5] != 'test_':
          tname = 'test_'+tname
        test_names = [tname]

      # Loop through all attributes of test_module
      for test_name in test_names:
        # If attribute is not a test case, skip it.
        if test_name[:5] != 'test_':
          continue

        try:
          # Create an instance of the test case object and run it
          test = apply( getattr(test_module,test_name), () )
          print '%-30s  ->  ' %(test_name),
          test.run()
        except base_test.TestFail, reason:
          print 'FAILED: %s' %(reason)
          num_fails += 1
          # Could also do a sys.exit(1) here is user wishes
          result = EXIT_STATUS_FAIL
        else:
          num_passes += 1
          print 'passed'

        num_tests += 1

      test_names = None
    test_modules = None

    # remove test_dir from the module search path
    sys.path.remove(test_dir)

  elapsed = sum(os.times()[:2]) - start_time

  print 
  print 'Ran %d tests in %.3f seconds [%0.3f tests/second].' % \
      (num_tests, elapsed, num_tests/elapsed)
  print '  Number of Passing Tests: %d' %(num_passes)
  print '  Number of Failing Tests: %d' %(num_fails)
  print
  
  return result

def usage():
  print >> sys.stderr, """
Usage: regress.py [options] [[test_]dir] [[test_]module[.py]] [[test_]case]
  The 'test_' prefix on all args is optional.
  The '.py' extension on the test_module arg is also optional.

Options:
  -h, --help      : print this message and exit
      --stall     : stall the regression engine when done
"""
  sys.exit(1)
  
if __name__ == '__main__':
  import getopt, time, socket, signal

  # Parse command line options
  try:
    opts, args = getopt.getopt(sys.argv[1:], "h", ["help", "stall"])
  except getopt.GetoptError:
    # print help information and exit:
    usage()

  stall = 0

  for o, a in opts:
    if o in ("-h", "--help"):
      usage()
    if o in ("--stall",):
      stall = 1

  if len(args) > 3:
    usage()

  status = run_tests()

  sys.exit(status)
