#
# Authors: Xiangfu Liu <xiangfu@sharism.cc>
#                      bitcoin: 1CGeqFzCZnAPEEcigr8LzmWTqf8cvo8toW
#
# License GPLv3 or later.  NO WARRANTY.
#

BASEDIR=${CURDIR}

SYNTOOL?=xst
BOARD?=milkymist-one

SDK_DIRS=libbase libhal libfpvm libnet
SW_DIRS=${SDK_DIRS} libhpdmc libfpvm libfpvm/x86-linux libfpvm/lm32-linux bios

CORE_DIRS=ac97 bt656cap conbus dmx fmlbrg fmlmeter hpdmc_ddr32 \
	 memcard pfpu rc5 softusb sysctl tmu2 uart vgafb

tools:
	make -C ${BASEDIR}/tools

bios: tools
	make -C ${BASEDIR}/software/bios

bitstream: tools
	make -C ${BASEDIR}/boards/${BOARD}/synthesis -f Makefile.${SYNTOOL}

sdk: tools
	for d in $(SDK_DIRS); do make -C ${BASEDIR}/software/$$d || exit 1; done

load-bitstream: bitstream
	make -C ${BASEDIR}/boards/${BOARD}/synthesis -f Makefile.${SYNTOOL} load

docs:
	make -C ${BASEDIR}/doc
	for d in $(CORE_DIRS); do make -C ${BASEDIR}/cores/$$d/doc || exit 1; done

sdk-install: sdk
	make -C ${BASEDIR}/software/libfpvm install
	make -C ${BASEDIR}/softusb-input install

tools-install: tools
	make -C ${BASEDIR}/tools install

.PHONY: clean load-bitstream tools
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
