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
microudp.o: ../../software/include/base/stdio.h
microudp.o: ../../software/include/base/stdlib.h
microudp.o: ../../software/include/base/crc.h
microudp.o: ../../software/include/base/irq.h
microudp.o: ../../software/include/hw/minimac.h
microudp.o: ../../software/include/hw/common.h
microudp.o: ../../software/include/hw/sysctl.h
microudp.o: ../../software/include/hw/interrupts.h
microudp.o: ../../software/include/net/microudp.h
tftp.o: ../../software/include/base/string.h
tftp.o: ../../software/include/base/stdlib.h
tftp.o: ../../software/include/net/microudp.h
tftp.o: ../../software/include/net/tftp.h
