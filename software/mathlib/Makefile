MMDIR?=../..
include $(MMDIR)/software/include.mak

OBJECTS=acosf.o asinf.o atanf.o cosf.o cotf.o expf.o floorf.o ldexpf.o logf.o modff.o sincosf.o sinf.o sqrtf.o tanf.o asincosf.o atan2f.o ceilf.o coshf.o fabsf.o frexpf.o log10f.o powf.o sincoshf.o sinhf.o tancotf.o tanhf.o

all: mathlib.a

mathlib.a: $(OBJECTS)
	$(AR) clr mathlib.a $(OBJECTS)
	$(RANLIB) mathlib.a

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o mathlib.a .*~ *~ Makefile.bak

# DO NOT DELETE

acosf.o: ../../software/include/math.h
asincosf.o: ../../software/include/math.h
asinf.o: ../../software/include/math.h
atan2f.o: ../../software/include/math.h
atanf.o: ../../software/include/math.h
ceilf.o: ../../software/include/math.h
cosf.o: ../../software/include/math.h
coshf.o: ../../software/include/math.h
cotf.o: ../../software/include/math.h
expf.o: ../../software/include/math.h
fabsf.o: ../../software/include/math.h
floorf.o: ../../software/include/math.h
frexpf.o: ../../software/include/math.h
ldexpf.o: ../../software/include/math.h
log10f.o: ../../software/include/math.h
logf.o: ../../software/include/math.h
modff.o: ../../software/include/math.h
powf.o: ../../software/include/math.h
sincosf.o: ../../software/include/math.h
sincoshf.o: ../../software/include/math.h
sinf.o: ../../software/include/math.h
sinhf.o: ../../software/include/math.h
sqrtf.o: ../../software/include/math.h
tancotf.o: ../../software/include/math.h
tanf.o: ../../software/include/math.h
tanhf.o: ../../software/include/math.h
