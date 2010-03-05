MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=mdio.o microudp.o tftp.o

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
microudp.o: ../../software/include/stdio.h ../../software/include/stdlib.h
microudp.o: ../../software/include/crc.h ../../software/include/hw/minimac.h
microudp.o: ../../software/include/hw/common.h
microudp.o: ../../software/include/hw/sysctl.h
microudp.o: ../../software/include/net/microudp.h
tftp.o: ../../software/include/stdio.h ../../software/include/stdlib.h
tftp.o: ../../software/include/string.h ../../software/include/net/microudp.h
tftp.o: ../../software/include/net/tftp.h
