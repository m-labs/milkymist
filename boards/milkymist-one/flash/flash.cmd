setMode -bscan
setCable -p auto
identify -inferir
identifyMPM
attachflash -position 1 -bpi "28F256J3F"
assignfiletoattachedflash -position 1 -file "../bitstream.mcs"
program -p 1 -dataWidth 16 -rs1 NONE -rs0 NONE -bpionly -e
assignfiletoattachedflash -position 1 -file "../bios.mcs"
program -p 1 -dataWidth 16 -rs1 NONE -rs0 NONE -bpionly
assignfiletoattachedflash -position 1 -file "../splash.mcs"
program -p 1 -dataWidth 16 -rs1 NONE -rs0 NONE -bpionly
quit
