TARGETS=bin2hex crc32 flterm makeraw

all: $(TARGETS)

%: %.c
	clang -O2 -Wall -I. -s -o $@ $<

makeraw: makeraw.c
	clang -O2 -Wall -s -o $@ $< -lgd

.PHONY: clean

clean:
	rm -f $(TARGETS) *.o
