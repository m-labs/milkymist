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

#ifndef __SND_H
#define __SND_H

#include <hw/ac97.h>

void snd_init();
void snd_isr_crrequest();
void snd_isr_crreply();
void snd_isr_dmar();
void snd_isr_dmaw();

unsigned int snd_ac97_read(unsigned int addr);
void snd_ac97_write(unsigned int addr, unsigned int value);

typedef void (*snd_callback)(short *buffer, void *user);

void snd_play_empty();
int snd_play_refill(short *buffer);
void snd_play_start(snd_callback callback, unsigned int nsamples, void *user);
void snd_play_stop();
int snd_play_active();

void snd_record_empty();
int snd_record_refill(short *buffer);
void snd_record_start(snd_callback callback, unsigned int nsamples, void *user);
void snd_record_stop();
int snd_record_active();

/*
 * Each sample has 2 channels and 16 bits per channel
 * making up 4 bytes per sample.
 */
#define SND_MAX_NSAMPLES (AC97_MAX_DMASIZE/4)

#endif /* __SND_H */
