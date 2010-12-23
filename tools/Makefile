TARGETS=bin2hex mkmmimg flterm makeraw byteswap

all: $(TARGETS)

%: %.c
	clang -O2 -Wall -I. -s -o $@ $<

makeraw: makeraw.c
	clang -O2 -Wall -s -o $@ $< -lgd

install: mkmmimg flterm
	cp mkmmimg /usr/bin
	cp flterm /usr/bin

.PHONY: clean install

clean:
	rm -f $(TARGETS) *.o
