/*
 * Milkymist SoC
 * Copyright (c) 2011 Michael Walle
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 * Copyright (C) Linus Torvalds and Linux kernel developers
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

#include <stdlib.h>

#include <base/irq.h>
#include <hw/uart.h>
#include <hw/interrupts.h>
#include <hw/gpio.h>
#include <hw/sysctl.h>

#define SUPPORT_P_CMD 1
#define SUPPORT_X_CMD 1
#define SUPPORT_Z_CMD 1
#define SUPPORT_Q_CMD 1

/* see crt0.S */
extern void clear_bss(void);

/* Convert the exception identifier to a signal number. */
static const char signals[] = {
    0,                 /* reset */
    5  /* SIGTRAP */,  /* breakpoint */
    11 /* SIGSEGV */,  /* instruction bus error */
    5  /* SIGTRAP */,  /* watchpoint */
    11 /* SIGSEGV */,  /* data bus error */
    8  /* SIGFPE */,   /* divide by zero */
    2  /* SIGINT */,   /* interrupt */
    1  /* SIGHUP */,   /* system call */
};

/* Stringification macro */
#define STRINGY_(x) #x
#define STRINGY(x) STRINGY_(x)

enum lm32_regnames {
  LM32_REG_R0, LM32_REG_R1, LM32_REG_R2, LM32_REG_R3, LM32_REG_R4, LM32_REG_R5,
  LM32_REG_R6, LM32_REG_R7, LM32_REG_R8, LM32_REG_R9, LM32_REG_R10,
  LM32_REG_R11, LM32_REG_R12, LM32_REG_R13, LM32_REG_R14, LM32_REG_R15,
  LM32_REG_R16, LM32_REG_R17, LM32_REG_R18, LM32_REG_R19, LM32_REG_R20,
  LM32_REG_R21, LM32_REG_R22, LM32_REG_R23, LM32_REG_R24, LM32_REG_R25,
  LM32_REG_GP, LM32_REG_FP, LM32_REG_SP, LM32_REG_RA, LM32_REG_EA, LM32_REG_BA,
  LM32_REG_PC, LM32_REG_EID, LM32_REG_EBA, LM32_REG_DEBA, LM32_REG_IE, NUM_REGS
};

/* BUFMAX defines the maximum number of characters in inbound/outbound buffers */
#define BUFMAX 800
#define BUFMAX_HEX 320  /* keep this in sync with BUFMAX */

/* I/O packet buffers */
static char remcom_in_buffer[BUFMAX + 1];
static char remcom_out_buffer[BUFMAX + 1];

/* Remember breakpoint and watchpoint addresses */
#ifdef SUPPORT_Z_CMD
#define BPSMAX 4
static unsigned int bp_address[BPSMAX];
#define WPSMAX 4
static unsigned int wp_address[WPSMAX];

/* Track breakpoints and watchpoints which are in use */
static unsigned int bpwp_enabled;
#endif

/* Remember if GDB was connected before */
static char gdb_connected;

/* Track DC register content, because register is write only */
static unsigned int dc;

/*
 * Common helper functions
 *
 */
static char *strcpy(char *dst, char *src)
{
    char *tmp = dst;
    while ((*dst++ = *src++) != '\0');
    return tmp;
}

#ifdef SUPPORT_Q_CMD
static int memcmp(const void *cs, const void *ct, size_t count)
{
    const unsigned char *su1, *su2;
    int res = 0;

    for (su1 = cs, su2 = ct; 0 < count; ++su1, ++su2, count--)
        if ((res = *su1 - *su2) != 0)
            break;
    return res;
}
#endif

static char get_debug_char(void)
{
    while (!(CSR_UART_STAT & UART_STAT_RX_EVT));
    CSR_UART_STAT = UART_STAT_RX_EVT;
    return (char)CSR_UART_RXTX;
}

static void put_debug_char(char c)
{
    CSR_UART_RXTX = c;
    /* loop on THRE, TX_EVT must not be cleared */
    while (!(CSR_UART_STAT & UART_STAT_THRE));
}

/*
 * Conversion helper functions
 */

/* For integer to ASCII conversion */
static const char hexchars[]="0123456789abcdef";
#define highhex(x) hexchars[(x >> 4) & 0xf]
#define lowhex(x)  hexchars[x & 0xf]

/* Convert ch from a hex digit to an int */
static int hex(unsigned char ch)
{
    if (ch >= 'a' && ch <= 'f') {
        return ch-'a'+10;
    }
    if (ch >= '0' && ch <= '9') {
        return ch-'0';
    }
    if (ch >= 'A' && ch <= 'F') {
        return ch-'A'+10;
    }
    return -1;
}

/*
 * Convert the memory pointed to by mem into hex, placing result in buf.
 * Return a pointer to the last char put in buf ('\0'), in case of mem fault,
 * return NULL.
 */
static char *mem2hex(char *mem, char *buf, int count)
{
    unsigned char ch;

    while (count-- > 0)
    {
        ch = *mem++;
        *buf++ = highhex(ch);
        *buf++ = lowhex(ch);
    }

    *buf = '\0';
    return buf;
}

/*
 * Convert the hex array pointed to by buf into binary to be placed in mem.
 * Return a pointer to the character AFTER the last byte written.
 */
static char *hex2mem(char *buf, char *mem, int count)
{
    int i;
    char ch;

    for (i = 0; i < count; i++)
    {
        /* convert hex data to 8-bit value */
        ch = hex(*buf++) << 4;
        ch |= hex(*buf++);
        /* attempt to write data to memory */
        *mem++ = ch;
    }

    return mem;
}

/*
 * Copy the binary data pointed to by buf to mem and return a pointer to the
 * character AFTER the last byte written $, # and 0x7d are escaped with 0x7d.
 */
#ifdef SUPPORT_X_CMD
static char *bin2mem(char *buf, char *mem, int count)
{
    int i;
    char c;

    for (i = 0; i < count; i++)
    {
        /* Convert binary data to unsigned byte */
        c = *buf++;
        if (c == 0x7d) {
            c = *buf++ ^ 0x20;
        }
        /* Attempt to write value to memory */
        *mem++ = c;
    }

    return mem;
}
#endif

/*
 * While we find nice hex chars, build an int.
 * Return number of chars processed.
 */
static int hex2int(char **ptr, unsigned int *value)
{
    int num_chars = 0;
    int hex_value;

    *value = 0;

    while(**ptr)
    {
        hex_value = hex(**ptr);
        if (hex_value < 0) {
            break;
        }

        *value = (*value << 4) | hex_value;
        num_chars++;

        (*ptr)++;
    }

    return num_chars;
}

/* Scan for the sequence $<data>#<checksum> */
static char *get_packet(void)
{
    char *buffer = remcom_in_buffer;
    unsigned char checksum;
    unsigned char xmitcsum;
    int count;
    char ch;

    while (1) {
        /* wait around for the start character, ignore all other characters */
        while ((ch = get_debug_char()) != '$');

        retry:
        checksum = 0;
        xmitcsum = -1;
        count = 0;

        /* now, read until a # or end of buffer is found */
        while (count < BUFMAX) {
            ch = get_debug_char();
            if (ch == '$') {
                goto retry;
            }
            if (ch == '#') {
                break;
            }
            checksum = checksum + ch;
            buffer[count] = ch;
            count = count + 1;
        }
        buffer[count] = 0;

        if (ch == '#') {
            ch = get_debug_char();
            xmitcsum = hex(ch) << 4;
            ch = get_debug_char();
            xmitcsum += hex(ch);

            if (checksum != xmitcsum) {
                /* failed checksum */
                put_debug_char('-');
            } else {
                /* successful transfer */
                put_debug_char('+');

                /* if a sequence char is present, reply the sequence ID */
                if (buffer[2] == ':') {
                    put_debug_char(buffer[0]);
                    put_debug_char(buffer[1]);

                    return &buffer[3];
                }
                return &buffer[0];
            }
        }
    }
}

/* Send the packet in buffer.  */
static void put_packet(char *buffer)
{
    unsigned char checksum;
    int count;
    unsigned char ch;

    /* $<packet info>#<checksum> */
    do {
        put_debug_char('$');
        checksum = 0;
        count = 0;

        while ((ch = buffer[count])) {
            put_debug_char(ch);
            checksum += ch;
            count += 1;
        }

        put_debug_char('#');
        put_debug_char(highhex(checksum));
        put_debug_char(lowhex(checksum));
    } while (get_debug_char() != '+');
}

static void flush_cache(void)
{
    __asm__ __volatile__("wcsr ICC, r0");
    __asm__ __volatile__("nop");
    __asm__ __volatile__("nop");
    __asm__ __volatile__("nop");
    __asm__ __volatile__("nop");
    __asm__ __volatile__("wcsr DCC, r0");
    __asm__ __volatile__("nop");
    __asm__ __volatile__("nop");
    __asm__ __volatile__("nop");
    __asm__ __volatile__("nop");
}

#ifdef SUPPORT_Z_CMD
static int set_hw_breakpoint(unsigned int address, int kind)
{
    int cfg;
    char num_bps;

    __asm__ __volatile__("rcsr %0, CFG" : "=r" (cfg));
    num_bps = (cfg >> 18) & 0xf;

    /* find a free breakpoint register */
    if (num_bps > 0 && (bpwp_enabled & 0x01) == 0) {
        __asm__ __volatile__("wcsr BP0, %0" : : "r" (address | 1));
        bpwp_enabled |= 0x01;
        bp_address[0] = address;
        return 1;
    }
    if (num_bps > 1 && (bpwp_enabled & 0x02) == 0) {
        __asm__ __volatile__("wcsr BP1, %0" : : "r" (address | 1));
        bpwp_enabled |= 0x02;
        bp_address[1] = address;
        return 1;
    }
    if (num_bps > 2 && (bpwp_enabled & 0x04) == 0) {
        __asm__ __volatile__("wcsr BP2, %0" : : "r" (address | 1));
        bpwp_enabled |= 0x04;
        bp_address[2] = address;
        return 1;
    }
    if (num_bps > 3 && (bpwp_enabled & 0x08) == 0) {
        __asm__ __volatile__("wcsr BP3, %0" : : "r" (address | 1));
        bpwp_enabled |= 0x08;
        bp_address[3] = address;
        return 1;
    }

    return 0;
}

static int set_hw_watchpoint(unsigned int address, int kind, char mode)
{
    int i;
    int bit = 0x10;
    int dc_mode = mode;
    int dc_mask = 0x0c;
    int cfg;
    char num_wps;

    __asm__ __volatile__("rcsr %0, CFG" : "=r" (cfg));
    num_wps = (cfg >> 22) & 0xf;

    /* find a free watchpoint register */
    for (i = 0; i < num_wps; i++) {
        if (!(bpwp_enabled & bit)) break;
        bit <<= 1;
        dc_mode <<= 2;
        dc_mask <<= 2;
    }

    if (i == num_wps) {
        return 0;
    }

    bpwp_enabled |= bit;
    wp_address[i] = address;
    dc &= ~dc_mask;
    dc |= dc_mode;
    __asm__ __volatile__("wcsr WP0, %0" : : "r" (address));
    __asm__ __volatile__("wcsr DC, %0"  : : "r" (dc));

    return 1;
}

static int disable_hw_breakpoint(unsigned int address, int kind)
{
    int cfg;

    __asm__ __volatile__("rcsr  %0, CFG" : "=r" (cfg));

    if ((bpwp_enabled & 0x01) && bp_address[0] == address) {
        __asm__ __volatile__("wcsr BP0, r0");
        bpwp_enabled &= ~0x01;
        return 1;
    }
    if ((bpwp_enabled & 0x02) && bp_address[1] == address) {
        __asm__ __volatile__("wcsr BP1, r0");
        bpwp_enabled &= ~0x02;
        return 1;
    }
    if ((bpwp_enabled & 0x04) && bp_address[2] == address) {
        __asm__ __volatile__("wcsr BP2, r0");
        bpwp_enabled &= ~0x04;
        return 1;
    }
    if ((bpwp_enabled & 0x08) && bp_address[3] == address) {
        __asm__ __volatile__("wcsr BP3, r0");
        bpwp_enabled &= ~0x08;
        return 1;
    }

    return 0;
}

static int disable_hw_watchpoint(unsigned int address, int kind, char mode)
{
    int i;
    int bit = 0x10;
    int dc_mode = mode;
    int dc_mask = 0x0c;

    for (i = 0; i < 4; i++) {
        if (bpwp_enabled & bit && wp_address[i] == address
                && (dc & dc_mask) == dc_mode) {
            bpwp_enabled &= ~bit;
            dc &= ~dc_mask;
            __asm__ __volatile__("wcsr DC, %0"  : : "r" (dc));
            return 1;
        }
        bit <<= 1;
        dc_mode <<= 2;
        dc_mask <<= 2;
    }

    return 0;
}
#endif

static void cmd_status(unsigned int *registers)
{
    char *ptr = remcom_out_buffer;
    int sigval;

    /* convert an exception ID to a signal number */
    sigval = signals[registers[LM32_REG_EID] & 0x7];

    *ptr++ = 'T';
    *ptr++ = highhex(sigval);
    *ptr++ = lowhex(sigval);
    *ptr++ = highhex(LM32_REG_PC);
    *ptr++ = lowhex(LM32_REG_PC);
    *ptr++ = ':';
    ptr = mem2hex((char *)&(registers[LM32_REG_PC]), ptr, 4);
    *ptr++ = ';';
    *ptr++ = highhex(LM32_REG_SP);
    *ptr++ = lowhex(LM32_REG_SP);
    *ptr++ = ':';
    ptr = mem2hex((char *)&(registers[LM32_REG_SP]), ptr, 4);
    *ptr++ = ';';
    *ptr++ = '\0';
}

static void cmd_getregs(unsigned int *registers)
{
    mem2hex((char *)registers, remcom_out_buffer, NUM_REGS * 4);
}

static void cmd_setregs(unsigned int *registers)
{
    hex2mem(&remcom_in_buffer[1], (char *)registers, NUM_REGS * 4);
    strcpy(remcom_out_buffer, "OK");
}

static void cmd_mem_read(void)
{
    char *ptr = &remcom_in_buffer[1];
    unsigned int length;
    unsigned int addr;

    /* try to read %x,%x */
    if (hex2int(&ptr, &addr) > 0 && *ptr++ == ',' && hex2int(&ptr, &length) > 0
            && length < (sizeof(remcom_out_buffer) / 2)) {
        if (mem2hex((char *)addr, remcom_out_buffer, length) == NULL) {
            strcpy(remcom_out_buffer, "E14");
        }
    } else {
        strcpy(remcom_out_buffer, "E22");
    }
}

static void cmd_mem_write(int binary)
{
    char *ptr = &remcom_in_buffer[1];
    unsigned int length;
    unsigned int addr;

    /* try to read '%x,%x:' */
    if (hex2int(&ptr, &addr) > 0 && *ptr++ == ','
            && hex2int(&ptr, &length) > 0 && *ptr++ == ':') {
#ifdef SUPPORT_X_CMD
        if (binary) {
            bin2mem(ptr, (char *)addr, length);
        } else {
            hex2mem(ptr, (char *)addr, length);
        }
#else
        hex2mem(ptr, (char *)addr, length);
        (void)binary;
#endif
        strcpy(remcom_out_buffer, "OK");
    } else {
        strcpy(remcom_out_buffer, "E22");
    }
}

static void remove_all_break(void)
{
    __asm__ __volatile__("wcsr DC, r0");
    __asm__ __volatile__("wcsr BP0, r0");
    __asm__ __volatile__("wcsr BP1, r0");
    __asm__ __volatile__("wcsr BP2, r0");
    __asm__ __volatile__("wcsr BP3, r0");
}

static void cmd_detachkill(void)
{
    remove_all_break();
    gdb_connected = 0;

    if (remcom_in_buffer[0] == 'D') {
        strcpy(remcom_out_buffer, "OK");
        put_packet(remcom_out_buffer);
    }
}

static void cmd_continuestep(unsigned int *registers)
{
    char *ptr = &remcom_in_buffer[1];
    unsigned int addr;

    if (hex2int(&ptr, &addr) > 0) {
        registers[LM32_REG_PC] = addr;
    }

    if (remcom_in_buffer[0] == 's') {
        /* singlestepping */
        __asm__ __volatile__("wcsr DC, %0" : : "r" (dc | 1));
    }
}

#ifdef SUPPORT_Z_CMD
static void cmd_break(void)
{
    char *ptr = &remcom_in_buffer[2];
    unsigned int addr;
    unsigned int kind;
    int err;
    char mode;

    if (*ptr++ == ',' && hex2int(&ptr, &addr) > 0
            && *ptr++ == ',' && hex2int(&ptr, &kind) > 0)
    {
        switch (remcom_in_buffer[1]) {
        case '1': /* h/w breakpoint */
            if (remcom_in_buffer[0] == 'Z') {
                err = set_hw_breakpoint(addr, kind);
            } else {
                err = disable_hw_breakpoint(addr, kind);
            }
            break;
        case '2': /* write watchpoint */
            mode = 2 << 2;
            goto do_set_clear_hw_watchpoint;
        case '3': /* read watchpoint */
            mode = 1 << 2;
            goto do_set_clear_hw_watchpoint;
        case '4': /* access watchpoint */
            mode = 3 << 2;
do_set_clear_hw_watchpoint:
            if (remcom_in_buffer[0] == 'Z') {
                err = set_hw_watchpoint(addr, kind, mode);
            } else {
                err = disable_hw_watchpoint(addr, kind, mode);
            }
            break;
        default:
            return;
        }
        if (err > 0) {
            strcpy(remcom_out_buffer, "OK");
        } else {
            strcpy(remcom_out_buffer, "E28");
        }
    } else {
        strcpy(remcom_out_buffer, "E22");
    }
}
#endif

static void cmd_reset(void)
{
    CSR_SYSTEM_ID = 1;
}

#ifdef SUPPORT_P_CMD
static void cmd_reg_get(unsigned int *registers)
{
    unsigned int reg;
    char *ptr = &remcom_in_buffer[1];

    if (hex2int(&ptr, &reg) > 0) {
        mem2hex((char *)&registers[reg], remcom_out_buffer, 4);
    } else {
        strcpy(remcom_out_buffer, "E22");
    }
}

static void cmd_reg_set(unsigned int *registers)
{
    unsigned int reg;
    char *ptr = &remcom_in_buffer[1];

    if (hex2int(&ptr, &reg) > 0 && *ptr++ == '=') {
        hex2mem(ptr, (char *)&registers[reg], 4);
        strcpy(remcom_out_buffer, "OK");
    } else {
        strcpy(remcom_out_buffer, "E22");
    }
}
#endif

#ifdef SUPPORT_Q_CMD
static void cmd_query(void)
{
    if (memcmp(&remcom_in_buffer[1], "Supported", 9) == 0) {
        strcpy(remcom_out_buffer, "PacketSize=" STRINGY(BUFMAX_HEX));
    }
}
#endif

/*
 * This function does all command processing for interfacing to gdb. The error
 * codes we return are errno numbers.
 */
void handle_exception(unsigned int *registers)
{
    unsigned int stat;

    /*
     * make sure break is disabled.
     * we can enter the stub with break enabled when the application calls it.
     * there is a race condition here if the break is asserted before this line
     * is executed, but the race window is small. to prevent it completely,
     * applications should disable debug exceptions before jumping to debug
     * ROM.
     */
    CSR_UART_DEBUG = 0;

    /* clear BSS there was a board reset */
    if (!CSR_DBG_SCRATCHPAD) {
        CSR_DBG_SCRATCHPAD = 1;
        clear_bss();
    }

    /* wait until TX transaction is finished. If there was a transmission in
     * progress, the event bit will be set. In this case, the gdbstub won't clear
     * it after it is terminated. */
    while(!(CSR_UART_STAT & UART_STAT_THRE));
    stat = CSR_UART_STAT;

    /* reply to host that an exception has occured */
    if (gdb_connected) {
        cmd_status(registers);
        put_packet(remcom_out_buffer);
    }

    while (1) {
        remcom_out_buffer[0] = '\0';
        get_packet();
        gdb_connected = 1;

        switch (remcom_in_buffer[0])
        {
        case '?': /* return last signal */
            cmd_status(registers);
            break;
        case 'g': /* return the value of the CPU registers */
            cmd_getregs(registers);
            break;
        case 'G': /* set the value of the CPU registers - return OK */
            cmd_setregs(registers);
            break;
        case 'm': /* read memory */
            cmd_mem_read();
            break;
        case 'M': /* write memory */
            cmd_mem_write(0);
            break;
#ifdef SUPPORT_X_CMD
        case 'X': /* write memory (binary) */
            cmd_mem_write(1);
            break;
#endif
#ifdef SUPPORT_P_CMD
        case 'p': /* return the value of the specified register */
            cmd_reg_get(registers);
            break;
        case 'P': /* set the specified register to the given value */
            cmd_reg_set(registers);
            break;
#endif
        case 'D': /* detach */
        case 'k': /* kill */
            cmd_detachkill();
            goto out;
        case 'c': /* continue */
        case 's': /* single step */
            cmd_continuestep(registers);
            goto out;
#ifdef SUPPORT_Z_CMD
        case 'z': /* remove breakpoint/watchpoint */
        case 'Z': /* insert breakpoint/watchpoint */
            cmd_break();
            break;
#endif
        case 'r': /* reset */
        case 'R': /* restart */
            cmd_reset();
            break;
#ifdef SUPPORT_Q_CMD
        case 'q': /* general query */
            cmd_query();
            break;
        }
#endif

        /* reply to the request */
        put_packet(remcom_out_buffer);
    }

out:
    flush_cache();

    /* clear TX event if there was no transmission in progress */
    CSR_UART_STAT = stat & UART_STAT_TX_EVT;

    /* reenable break */
    CSR_UART_DEBUG = UART_DEBUG_BREAK_EN;
}
