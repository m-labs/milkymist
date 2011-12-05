#
# Authors: Xiangfu Liu <xiangfu@sharism.cc>
#                      bitcoin: 1CGeqFzCZnAPEEcigr8LzmWTqf8cvo8toW
#
# License GPLv3 or later.  NO WARRANTY.
#

BASEDIR=${CURDIR}

SYNTOOL?=xst
BOARD?=milkymist-one

PORT?=/dev/ttyUSB0
LOADADDR?=0x40000000
IMAGE?=${BASEDIR}/software/demo/boot.bin

SDK_DIRS=libbase libmath libhal libfpvm libnet
SW_DIRS=${SDK_DIRS} libhpdmc libfpvm/x86-linux libfpvm/lm32-linux libfpvm/lm32-rtems bios demo

CORE_DIRS=ac97 bt656cap conbus dmx fmlbrg fmlmeter hpdmc_ddr32 \
	 memcard pfpu rc5 softusb sysctl tmu2 uart vgafb

host:
	make -C ${BASEDIR}/tools

bios: host
	make -C ${BASEDIR}/software/bios

bitstream: host
	make -C ${BASEDIR}/boards/${BOARD}/synthesis -f Makefile.${SYNTOOL}

demo: host
	make -C ${BASEDIR}/software/demo

sdk: host
	for d in $(SDK_DIRS); do make -C ${BASEDIR}/software/$$d || exit 1; done

load-bitstream: bitstream
	make -C ${BASEDIR}/boards/${BOARD}/synthesis -f Makefile.${SYNTOOL} load

load-demo: demo
	${BASEDIR}/tools/flterm --port ${PORT} --kernel ${BASEDIR}/${IMAGE} --kernel-adr ${LOADADDR}

docs:
	make -C ${BASEDIR}/doc
	for d in $(CORE_DIRS); do make -C ${BASEDIR}/cores/$$d/doc || exit 1; done

.PHONY: clean load-demo load-bitstream
clean:
	make -C ${BASEDIR}/boards/milkymist-one/synthesis -f common.mak clean
	make -C ${BASEDIR}/boards/milkymist-one/standby clean
	make -C ${BASEDIR}/boards/milkymist-one/flash clean
	make -C ${BASEDIR}/doc clean
	make -C ${BASEDIR}/tools clean
	make -C ${BASEDIR}/softusb-input clean
	for d in $(CORE_DIRS); do make -C ${BASEDIR}/cores/$$d/doc clean || exit 1; done
	for d in $(SW_DIRS); do make -C ${BASEDIR}/software/$$d clean || exit 1; done
	(cd ${BASEDIR}/cores/pfpu ./cleanroms.sh)
