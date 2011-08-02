/*
 * Milkymist SoC
 * Copyright (c) 2010 Michael Walle
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

.section    .text, "ax", @progbits
.global     _start
.global     clear_bss

_start:
_reset_handler:
    xor     r0, r0, r0                  /* clear r0 */
    wcsr    IE, r0			/* disable interrupts */
    mvi     ba, 0
    bi      _breakpoint_handler         /* just call our bp handler */
    nop
    nop
    nop
    nop

_breakpoint_handler:
    xor     r0, r0, r0                  /* clear r0, in case its corrupted */
    mvhi    r0, hi(_debug_stack)        /* temporary stack pointer */
    ori     r0, r0, lo(_debug_stack)
    sw      (r0+0), ra                  /* save ra, calli overwrites it */
    calli   save_all                    /* after this, sp is our debug stack */
    sw      (sp+128), ba                /* save pc */
    calli   handle_exception
    bi      b_restore_and_return

_instruction_bus_error_handler:
    xor     r0, r0, r0                  /* clear r0, in case its corrupted */
    mvhi    r0, hi(_debug_stack)        /* temporary stack pointer */
    ori     r0, r0, lo(_debug_stack)
    sw      (r0+0), ra                  /* save ra, calli overwrites it */
    calli   save_all                    /* after this, sp is our debug stack */
    sw      (sp+128), ea                /* save pc */
    calli   handle_exception
    bi      e_restore_and_return

_watchpoint_handler:
    xor     r0, r0, r0                  /* clear r0, in case its corrupted */
    mvhi    r0, hi(_debug_stack)        /* temporary stack pointer */
    ori     r0, r0, lo(_debug_stack)
    sw      (r0+0), ra                  /* save ra, calli overwrites it */
    calli   save_all                    /* after this, sp is our debug stack */
    sw      (sp+128), ba                /* save pc */
    calli   handle_exception
    bi      b_restore_and_return

_data_bus_error_handler:
    xor     r0, r0, r0                  /* clear r0, in case its corrupted */
    mvhi    r0, hi(_debug_stack)        /* temporary stack pointer */
    ori     r0, r0, lo(_debug_stack)
    sw      (r0+0), ra                  /* save ra, calli overwrites it */
    calli   save_all                    /* after this, sp is our debug stack */
    sw      (sp+128), ea                /* save pc */
    calli   handle_exception
    bi      e_restore_and_return

_divide_by_zero_handler:
    xor     r0, r0, r0                  /* clear r0, in case its corrupted */
    mvhi    r0, hi(_debug_stack)        /* temporary stack pointer */
    ori     r0, r0, lo(_debug_stack)
    sw      (r0+0), ra                  /* save ra, calli overwrites it */
    calli   save_all                    /* after this, sp is our debug stack */
    sw      (sp+128), ea                /* save pc */
    calli   handle_exception
    bi      e_restore_and_return

_interrupt_handler:
    xor     r0, r0, r0                  /* clear r0, in case its corrupted */
    mvhi    r0, hi(_debug_stack)        /* temporary stack pointer */
    ori     r0, r0, lo(_debug_stack)
    sw      (r0+0), ra                  /* save ra, calli overwrites it */
    calli   save_all                    /* after this, sp is our debug stack */
    sw      (sp+128), ea		/* save pc */
    calli   handle_exception
    bi      e_restore_and_return

_system_call_handler:
    xor     r0, r0, r0                  /* clear r0, in case its corrupted */
    mvhi    r0, hi(_debug_stack)        /* temporary stack pointer */
    ori     r0, r0, lo(_debug_stack)
    sw      (r0+0), ra                  /* save ra, calli overwrites it */
    calli   save_all                    /* after this, sp is our debug stack */
    sw      (sp+128), ea                /* save pc */
    calli   handle_exception
    bi      e_restore_and_return

/* save all registers onto the stack */ 
save_all:        
    /* save origin sp */
    addi    r0, r0, -156
    /* save registers */
    /* 0 - R0 - saved below */
    sw      (r0+4), r1
    sw      (r0+8), r2
    sw      (r0+12), r3
    sw      (r0+16), r4
    sw      (r0+20), r5
    sw      (r0+24), r6
    sw      (r0+28), r7
    sw      (r0+32), r8
    sw      (r0+36), r9
    sw      (r0+40), r10
    sw      (r0+44), r11
    sw      (r0+48), r12
    sw      (r0+52), r13
    sw      (r0+56), r14
    sw      (r0+60), r15
    sw      (r0+64), r16
    sw      (r0+68), r17
    sw      (r0+72), r18
    sw      (r0+76), r19
    sw      (r0+80), r20
    sw      (r0+84), r21
    sw      (r0+88), r22
    sw      (r0+92), r23
    sw      (r0+96), r24
    sw      (r0+100), r25
    sw      (r0+104), r26
    sw      (r0+108), r27
    sw      (r0+112), sp
    /* 116 - RA - saved below */
    sw      (r0+120), ea
    sw      (r0+124), ba
    /* 128 - PC - saved in handler code above */
    /* 132 - EID - saved below */
    rcsr    r1, EBA
    sw      (r0+136), r1
    rcsr    r1, DEBA
    sw      (r0+140), r1
    rcsr    r1, IE
    sw      (r0+144), r1
    rcsr    r1, IM
    sw      (r0+148), r1
    rcsr    r1, IP
    sw      (r0+152), r1

    /* work out EID from exception entry point address */
    andi    r1, ra, 0xff
    srui    r1, r1, 5
    sw      (r0+132), r1
    
    /* switch sp to debug stack. We can't use mv yet, as r0
     * is not 0. */
    sw      (r0+116), r0
    lw      sp, (r0+116)
    
    /* restore r0 to 0 */
    xor     r0, r0, r0
    
    /* fix ra */
    lw      r1, (sp+156)
    sw      (sp+116), r1
    
    /* save r0 (hardcoded to 0) */
    sw      (sp+0), r0
    
    /* save pointer to registers, this is the first argument for
     * handle_exception(), so save it in r1 */
    mv      r1, sp
    ret

/* Restore gp registers */
restore_gp:
    lw      r1, (sp+4)
    lw      r2, (sp+8) 
    lw      r3, (sp+12) 
    lw      r4, (sp+16) 
    lw      r5, (sp+20) 
    lw      r6, (sp+24) 
    lw      r7, (sp+28) 
    lw      r8, (sp+32) 
    lw      r9, (sp+36) 
    lw      r10, (sp+40)
    lw      r11, (sp+44)
    lw      r12, (sp+48)
    lw      r13, (sp+52)
    lw      r14, (sp+56)
    lw      r15, (sp+60)
    lw      r16, (sp+64)
    lw      r17, (sp+68)
    lw      r18, (sp+72)
    lw      r19, (sp+76)
    lw      r20, (sp+80)
    lw      r21, (sp+84)
    lw      r22, (sp+88)
    lw      r23, (sp+92)
    lw      r24, (sp+96)
    lw      r25, (sp+100)
    lw      r26, (sp+104)
    lw      r27, (sp+108)
    ret

/* restore registers and return from exception */
e_restore_and_return:
    /* first restore gp registers */
    calli   restore_gp
    lw      ra, (sp+116)
    lw      ba, (sp+124)
    lw      ea, (sp+136)
    wcsr    EBA, ea
    lw      ea, (sp+140)
    wcsr    DEBA, ea
    lw      ea, (sp+144)
    wcsr    IE, ea
    lw      ea, (sp+148)
    wcsr    IM, ea
    /* restore EA from PC */        
    lw      ea, (sp+128)
    /* stack pointer must be restored last, in case it has been updated */
    lw      sp, (sp+112)
    eret

/* restore registers and return from breakpoint */
b_restore_and_return:
    /* first restore gp registers */
    calli   restore_gp
    lw      ra, (sp+116)
    lw      ea, (sp+120)
    lw      ba, (sp+136)
    wcsr    EBA, ba
    lw      ba, (sp+140)
    wcsr    DEBA, ba
    lw      ba, (sp+144)
    wcsr    IE, ba
    lw      ba, (sp+148)
    wcsr    IM, ba
    /* restore BA from PC */        
    lw 	ba, (sp+128)
    /* stack pointer must be restored last, in case it has been updated */
    lw	sp, (sp+112)
    bret

/* clear BSS, this is called from handle_exception() */
clear_bss:
    mvhi    r1, hi(_fbss)
    ori     r1, r1, lo(_fbss)
    mvhi    r2, hi(_ebss)
    ori     r2, r2, lo(_ebss)
1:
    be      r1, r2, 2f
    sw      (r1+0), r0
    addi    r1, r1, 4
    bi      1b
2:
    ret
