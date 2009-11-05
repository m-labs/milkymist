new_project -name "milkymist" -folder "." -createimpl_name "milkymist_impl"

setup_design -manufacturer "Xilinx" -family "VIRTEX-4" -part "4VLX25FF668" -speed "10"
setup_design -retiming
setup_design -max_fanout=10000
setup_design -design "system"
setup_design -basename "system"

setup_design -compile_for_area=false
setup_design -compile_for_timing=true

source "loadsources.tcl"
add_input_file "system.ucf" -exclude="false"
add_input_file "../ioffs.sdc"

compile
synthesize

save_impl
close_project
