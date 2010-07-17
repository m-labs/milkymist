/* Based on http://www.lvr.com/files/usb_crc.c by Ron Hemphill */

#define INT_SIZE 32
unsigned char usb_crc5(unsigned int input, int bit_count)
{
	const unsigned int poly5 = (0x05 << (INT_SIZE-5));
	unsigned int crc5  = (0x1f << (INT_SIZE-5));
	unsigned int udata = (input << (INT_SIZE-bit_count));

	while(bit_count--) {
		// bit4 != bit4?
		if((udata ^ crc5) & (0x1<<(INT_SIZE-1))) {
			crc5 <<= 1;
			crc5 ^= poly5;
		} else
			crc5 <<= 1;
		udata <<= 1;
	}

	// Shift back into position
	crc5 >>= (INT_SIZE-5);

	// Invert contents to generate crc field
	crc5 ^= 0x1f;

	return crc5;
}
