all: flasher

%: %.c
	gcc -O2 -Wall -s -o $@ $< `pkg-config --cflags --libs libusb-1.0`

.PHONY: clean

clean:
	rm -f flasher *.o
