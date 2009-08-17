TARGETS=crc32 flterm bin2hex

all: $(TARGETS)

%: %.c
	gcc -O2 -Wall -I../std -s -o $@ $<

.PHONY: clean

clean:
	rm -f $(TARGETS) *.o
