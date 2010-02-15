all: floatconv.so

floatconv.so: floatconv.o
	ld -G -shared -export-dynamic -o floatconv.so floatconv.o

floatconv.o: floatconv.c
	gcc -I/usr/include/cver -fPIC -Wall -g -O2 -c -o floatconv.o floatconv.c

clean:
	rm -f floatconv.o floatconv.so

.PHONY: clean
