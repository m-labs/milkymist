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

#ifndef __HAL_USB_H
#define __HAL_USB_H

typedef void (*mouse_event_cb)(unsigned char buttons, char dx, char dy, unsigned char wheel);
typedef void (*keyboard_event_cb)(unsigned char modifiers, unsigned char key);

void usb_init(void);
void usb_debug_enable(int en);
void usb_set_mouse_cb(mouse_event_cb cb);
void usb_set_keyboard_cb(keyboard_event_cb cb);

void usb_isr(void);

#endif /* __HAL_USB_H */
