#!/usr/bin/python

import sys

def extract_bits(n, start, count):
	mask = 2**count - 1
	return (n & (mask << start)) >> start

def split_adr(adr):
	return extract_bits(adr, 12, 27-2-12+1), extract_bits(adr, 10, 2), extract_bits(adr, 0, 10)

def count_page_hits(adrs):
	openrows = [0]*4
	page_hits = 0
	for adr in adrs:
		row, bank, col = split_adr(adr)
		if openrows[bank] == row:
			page_hits += 1
		openrows[bank] = row
	return page_hits

def reorder(adrs, window_size):
	window = []
	openrows = [0]*4
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
	print "%d, %d" % (p, 100*count_page_hits(adrs)/transaction_count)

print "Reading input..."
transaction_count = 0
unordered_adrs = []
for line in sys.stdin:
	unordered_adrs.append(int(line, 16) >> 2) # express address in 32-bit words
	transaction_count += 1

print "...done."
print "Transaction count: %d" % transaction_count

print_page_hits(1, unordered_adrs)
for window_size in [2, 3, 4, 5, 6, 7, 8, 9, 10, 25, 50, 100]:
	reordered = reorder(unordered_adrs, window_size)
	print_page_hits(window_size, reordered)
