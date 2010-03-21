MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=acosf.o asinf.o atanf.o cosf.o cotf.o expf.o floorf.o ldexpf.o logf.o modff.o sincosf.o sinf.o sqrtf.o tanf.o asincosf.o atan2f.o ceilf.o coshf.o fabsf.o frexpf.o log10f.o powf.o sincoshf.o sinhf.o tancotf.o tanhf.o

all: libmath.a

libmath.a: $(OBJECTS)
	$(AR) clr libmath.a $(OBJECTS)
	$(RANLIB) libmath.a

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o libmath.a .*~ *~ Makefile.bak

# DO NOT DELETE

acosf.o: ../../software/include/base/math.h
asincosf.o: ../../software/include/base/math.h
asinf.o: ../../software/include/base/math.h
atan2f.o: ../../software/include/base/math.h
atanf.o: ../../software/include/base/math.h
ceilf.o: ../../software/include/base/math.h
cosf.o: ../../software/include/base/math.h
coshf.o: ../../software/include/base/math.h
cotf.o: ../../software/include/base/math.h
expf.o: ../../software/include/base/math.h
fabsf.o: ../../software/include/base/math.h
floorf.o: ../../software/include/base/math.h
frexpf.o: ../../software/include/base/math.h
ldexpf.o: ../../software/include/base/math.h
log10f.o: ../../software/include/base/math.h
logf.o: ../../software/include/base/math.h
modff.o: ../../software/include/base/math.h
powf.o: ../../software/include/base/math.h
sincosf.o: ../../software/include/base/math.h
sincoshf.o: ../../software/include/base/math.h
sinf.o: ../../software/include/base/math.h
sinhf.o: ../../software/include/base/math.h
sqrtf.o: ../../software/include/base/math.h
tancotf.o: ../../software/include/base/math.h
tanf.o: ../../software/include/base/math.h
tanhf.o: ../../software/include/base/math.h
