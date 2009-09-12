/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

#ifndef __SFL_H
#define __SFL_H

#define SFL_MAGIC_LEN 14
#define SFL_MAGIC_REQ "sL5DdSMmkekro\n"
#define SFL_MAGIC_ACK "z6IHG7cYDID6o\n"

struct sfl_frame {
	unsigned char length;
	unsigned char crc[2];
	unsigned char cmd;
	unsigned char payload[255];
} __attribute__((packed));

/* General commands */
#define SFL_CMD_ABORT		0x00
#define SFL_CMD_LOAD		0x01
#define SFL_CMD_JUMP		0x02

/* Linux-specific commands */
#define SFL_CMD_CMDLINE		0x03
#define SFL_CMD_INITRDSTART	0x04
#define SFL_CMD_INITRDEND	0x05

/* Replies */
#define SFL_ACK_SUCCESS		'K'
#define SFL_ACK_CRCERROR	'C'
#define SFL_ACK_UNKNOWN		'U'
#define SFL_ACK_ERROR		'E'

#endif /* __SFL_H */
