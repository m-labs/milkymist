/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

#ifndef __HAL_SND_H
#define __HAL_SND_H

#include <hw/ac97.h>

void snd_init(void);
void snd_isr_crrequest(void);
void snd_isr_crreply(void);
void snd_isr_dmar(void);
void snd_isr_dmaw(void);

unsigned int snd_ac97_read(unsigned int addr);
void snd_ac97_write(unsigned int addr, unsigned int value);

typedef void (*snd_callback)(short *buffer, void *user);

void snd_play_empty(void);
int snd_play_refill(short *buffer);
void snd_play_start(snd_callback callback, unsigned int nsamples, void *user);
void snd_play_stop(void);
int snd_play_active(void);

void snd_record_empty(void);
int snd_record_refill(short *buffer);
void snd_record_start(snd_callback callback, unsigned int nsamples, void *user);
void snd_record_stop(void);
int snd_record_active(void);

/*
 * Each sample has 2 channels and 16 bits per channel
 * making up 4 bytes per sample.
 */
#define SND_MAX_NSAMPLES (AC97_MAX_DMASIZE/4)

#endif /* __HAL_SND_H */
