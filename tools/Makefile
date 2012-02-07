TARGETS=bin2hex mkmmimg flterm makeraw byteswap
CC=clang

all: $(TARGETS)

%: %.c
	$(CC) -O2 -Wall -I. -s -o $@ $<

makeraw: makeraw.c
	$(CC) -O2 -Wall -s -o $@ $< -lgd

install: mkmmimg flterm
	install -d /usr/local/bin
	install -m755 -t /usr/local/bin $^

.PHONY: clean install

clean:
	rm -f $(TARGETS) *.o
