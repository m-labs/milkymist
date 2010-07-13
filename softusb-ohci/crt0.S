.section ".text","ax"
.globl _start, _memreg
.org 0x20
/* NB! this first part of the startup code will be destroyed
 * at runtim (re-used for memreg)
 */
_start:
_memreg:
	/* put SP at the end of the RAM */
	im 0x4000
	popsp
	/* run main() */
	im main
	poppc

/* make sure we have enough space at the beginning for R0, R1, R2 */
.org 0x2c
