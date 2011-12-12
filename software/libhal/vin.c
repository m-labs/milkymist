/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <hal/vin.h>
#include <hw/bt656cap.h>

static int i2c_started;

static int i2c_init(void)
{
	unsigned int timeout;

	i2c_started = 0;
	CSR_BT656CAP_I2C = BT656CAP_I2C_SDC;
	/* Check the I2C bus is ready */
	timeout = 1000;
	while((timeout > 0) && (!(CSR_BT656CAP_I2C & BT656CAP_I2C_SDAIN))) timeout--;

	return timeout;
}

static void i2c_delay(void)
{
	unsigned int i;

	for(i=0;i<1000;i++) __asm__("nop");
}

/* I2C bit-banging functions from http://en.wikipedia.org/wiki/I2c */
static unsigned int i2c_read_bit(void)
{
	unsigned int bit;

	/* Let the slave drive data */
	CSR_BT656CAP_I2C = 0;
	i2c_delay();
	CSR_BT656CAP_I2C = BT656CAP_I2C_SDC;
	i2c_delay();
	bit = CSR_BT656CAP_I2C & BT656CAP_I2C_SDAIN;
	i2c_delay();
	CSR_BT656CAP_I2C = 0;
	return bit;
}

static void i2c_write_bit(unsigned int bit)
{
	if(bit) {
		CSR_BT656CAP_I2C = BT656CAP_I2C_SDAOE|BT656CAP_I2C_SDAOUT;
	} else {
		CSR_BT656CAP_I2C = BT656CAP_I2C_SDAOE;
	}
	i2c_delay();
	/* Clock stretching */
	CSR_BT656CAP_I2C |= BT656CAP_I2C_SDC;
	i2c_delay();
	CSR_BT656CAP_I2C &= ~BT656CAP_I2C_SDC;
}

static void i2c_start_cond(void)
{
	if(i2c_started) {
		/* set SDA to 1 */
		CSR_BT656CAP_I2C = BT656CAP_I2C_SDAOE|BT656CAP_I2C_SDAOUT;
		i2c_delay();
		CSR_BT656CAP_I2C |= BT656CAP_I2C_SDC;
	}
	/* SCL is high, set SDA from 1 to 0 */
	CSR_BT656CAP_I2C = BT656CAP_I2C_SDAOE|BT656CAP_I2C_SDC;
	i2c_delay();
	CSR_BT656CAP_I2C = BT656CAP_I2C_SDAOE;
	i2c_started = 1;
}

static void i2c_stop_cond(void)
{
	/* set SDA to 0 */
	CSR_BT656CAP_I2C = BT656CAP_I2C_SDAOE;
	i2c_delay();
	/* Clock stretching */
	CSR_BT656CAP_I2C = BT656CAP_I2C_SDAOE|BT656CAP_I2C_SDC;
	/* SCL is high, set SDA from 0 to 1 */
	CSR_BT656CAP_I2C = BT656CAP_I2C_SDC;
	i2c_delay();
	i2c_started = 0;
}

static unsigned int i2c_write(unsigned char byte)
{
	unsigned int bit;
	unsigned int ack;

	for(bit = 0; bit < 8; bit++) {
		i2c_write_bit(byte & 0x80);
		byte <<= 1;
	}
	ack = !i2c_read_bit();
	return ack;
}

static unsigned char i2c_read(int ack)
{
	unsigned char byte = 0;
	unsigned int bit;

	for(bit = 0; bit < 8; bit++) {
		byte <<= 1;
		byte |= i2c_read_bit();
	}
	i2c_write_bit(!ack);
	return byte;
}

static const char vreg_addr[] = {
	0x15, 0x17, 0x1D, 0x0F, 0x3A, 0x3D, 0x3F, 0x50, 0xC3, 0xC4, 0x0E, 0x50, 0x52, 0x58, 0x77, 0x7C, 0x7D, 0x90, 0x91, 0x92, 0x93, 0x94, 0xCF, 0xD0, 0xD6, 0xE5, 0xD5, 0xD7, 0xE4, 0xEA, 0xE9, 0x0E
};

static const char vreg_dat[] = {
	0x00, 0x41, 0x40, 0x40, 0x16, 0xC3, 0xE4, 0x04, 0x05, 0x80, 0x80, 0x20, 0x18, 0xED, 0xC5, 0x93, 0x00, 0xC9, 0x40, 0x3C, 0xCA, 0xD5, 0x50, 0x4E, 0xDD, 0x51, 0xA0, 0xEA, 0x3E, 0x0F, 0x3E, 0x00
};

void vin_init(void)
{
	int i;
	
	if(i2c_init())
		printf("VIN: I2C bus initialized\n");
	else
		printf("VIN: I2C bus initialization problem\n");
	for(i=0;i<sizeof(vreg_addr);i++)
		vin_write_reg(vreg_addr[i], vreg_dat[i]);
}

unsigned char vin_read_reg(unsigned char addr)
{
	unsigned char r;

	i2c_start_cond();
	i2c_write(0x40);
	i2c_write(addr);
	i2c_start_cond();
	i2c_write(0x41);
	r = i2c_read(0);
	i2c_stop_cond();

	return r;
}

void vin_write_reg(unsigned char addr, unsigned char val)
{
	i2c_start_cond();
	i2c_write(0x40);
	i2c_write(addr);
	i2c_write(val);
	i2c_stop_cond();
}
