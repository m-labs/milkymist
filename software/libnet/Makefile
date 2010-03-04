MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=mdio.o microudp.o

all: libnet.a

libnet.a: $(OBJECTS)
	$(AR) clr libnet.a $(OBJECTS)
	$(RANLIB) libnet.a

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o libnet.a .*~ *~ Makefile.bak
# DO NOT DELETE

mdio.o: ../../software/include/hw/minimac.h
mdio.o: ../../software/include/hw/common.h ../../software/include/net/mdio.h
