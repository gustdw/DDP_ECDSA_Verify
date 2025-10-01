# Set Vitis workspace
setws ./project_sw
# Add platform
#platform create -name pynq_z2 -hw src/tcl/ecc_project_wrapper.xsa -no-boot-bsp -out ../../

# Create application project
app create -name sw_design -hw src/tcl/ecc_project_wrapper.xsa -proc ps7_cortexa9_0 -os standalone -lang C
app build -name sw_design 


