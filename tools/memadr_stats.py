#!/usr/bin/python

#
# Parameters of the memory system
#
# log2 of the memory capacity, in bytes
param_capacity = 27
# log2 of the number of DRAM banks
param_banks = 2
# log2 of the size of a DRAM row, in 32-bit words
param_rowsize = 10
# burst length
param_burstlength = 4
# dead time, per transaction
param_deadtime = 2
# page miss penalty
param_misspenalty = 6
#

import sys

def extract_bits(n, start, count):
	mask = 2**count - 1
	return (n & (mask << start)) >> start

def split_adr(adr):
	return extract_bits(adr, param_rowsize+param_banks, param_capacity-2-param_rowsize-param_banks+1), extract_bits(adr, param_rowsize, param_banks), extract_bits(adr, 0, param_rowsize)

def count_page_hits(adrs):
	openrows = [0]*(2**param_banks)
	page_hits = 0
	for adr in adrs:
		row, bank, col = split_adr(adr)
		if openrows[bank] == row:
			page_hits += 1
		openrows[bank] = row
	return page_hits

def reorder(adrs, window_size):
	window = []
	openrows = [0]*(2**param_banks)
	def fetch_transaction():
		for candidate in window:
			row, bank, col = split_adr(candidate)
			if openrows[bank] == row:
				window.remove(candidate)
				return candidate
		candidate = window[0]
		row, bank, col = split_adr(candidate)
		openrows[bank] = row
		window.remove(candidate)
		return candidate
	out = []
	for adr in adrs:
		if len(window) == window_size:
			out.append(fetch_transaction())
		window.append(adr)
	for i in range(0, window_size):
		out.append(fetch_transaction())
	return out

def print_page_hits(p, adrs):
	hit_rate = float(count_page_hits(adrs))/float(transaction_count)
	utilization = hit_rate*float(param_burstlength)/float(param_burstlength+param_deadtime) + (1.0-hit_rate)*float(param_burstlength)/float(param_deadtime+param_misspenalty+param_burstlength)
	print "%d, %d, %d" % (p, 100*hit_rate, 100*utilization)

print "======= DRAM model parameters ======="
print "Memory capacity: %dMB" % ((2**param_capacity)/(1024*1024))
print "DRAM banks:      %d" % (2**param_banks)
print "Row size:        %d words (32-bit)" % (2**param_rowsize)
print "Burst length:    %d" % param_burstlength
print "Dead time:       %d" % param_deadtime
print "Miss penalty:    %d" % param_misspenalty

print "=======    Reading input...   ======="
transaction_count = 0
unordered_adrs = []
for line in sys.stdin:
	unordered_adrs.append(int(line, 16) >> 2) # express address in 32-bit words
	transaction_count += 1

print "...done."
print "Transaction count: %d" % transaction_count

print "=======    Full reordering    ======="
print "(window size, page hit rate, utilization)"
print_page_hits(1, unordered_adrs)
for window_size in [2, 3, 4, 5, 6, 7, 8, 9, 10, 25, 50, 100]:
	reordered = reorder(unordered_adrs, window_size)
	print_page_hits(window_size, reordered)
