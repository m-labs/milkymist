# Mico32 toolchain
#
CROSS_COMPILER=lm32-rtems4.11-

# Choose a compiler - gcc or clang
#CC_normal := clang -march=mico32 -ccc-host-triple mico32-elf -ccc-gcc-name lm32-rtems4.11-gcc
CC_normal := $(CROSS_COMPILER)gcc

AR_normal := $(CROSS_COMPILER)ar
AS_normal := $(CROSS_COMPILER)as
LD_normal := $(CROSS_COMPILER)ld
OBJCOPY_normal := $(CROSS_COMPILER)objcopy
RANLIB_normal  := $(CROSS_COMPILER)ranlib

CC_quiet = @echo " CC " $@ && $(CROSS_COMPILER)gcc
AR_quiet = @echo " AR " $@ && $(CROSS_COMPILER)ar
AS_quiet = @echo " AS " $@ && $(CROSS_COMPILER)as
LD_quiet = @echo " LD " $@ && $(CROSS_COMPILER)ld
OBJCOPY_quiet = @echo " OBJCOPY " $@ && $(CROSS_COMPILER)objcopy
RANLIB_quiet  = @echo " RANLIB  " $@ && $(CROSS_COMPILER)ranlib

ifeq ($(V),1)
    CC = $(CC_normal)
    AR = $(AR_normal)
    AS = $(AS_normal)
    LD = $(LD_normal)
    OBJCOPY = $(OBJCOPY_normal)
    RANLIB  = $(RANLIB_normal)
else
    CC = $(CC_quiet)
    AR = $(AR_quiet)
    AS = $(AS_quiet)
    LD = $(LD_quiet)
    OBJCOPY = $(OBJCOPY_quiet)
    RANLIB  = $(RANLIB_quiet)
endif

# Toolchain options
#
INCLUDES_NOLIBC ?= -nostdinc -I$(MMDIR)/software/include/base
INCLUDES = $(INCLUDES_NOLIBC) -I$(MMDIR) -I$(MMDIR)/software/include -I$(MMDIR)/tools
ASFLAGS = $(INCLUDES) -nostdinc
# later: -Wmissing-prototypes
CFLAGS = -O9 -Wall -Wstrict-prototypes -Wold-style-definition -Wshadow \
	 -mbarrel-shift-enabled -mmultiply-enabled -mdivide-enabled \
	 -msign-extend-enabled -fno-builtin -fsigned-char \
	 -fsingle-precision-constant $(INCLUDES)
LDFLAGS = -nostdlib -nodefaultlibs
