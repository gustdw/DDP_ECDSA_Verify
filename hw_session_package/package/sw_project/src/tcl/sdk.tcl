setws ./project_sw
#createhw -name hw_platform -hwspec hwdef.hdf
#createbsp -name hw_bsp -hwproject hw_platform -proc ps7_cortexa9_0 -os standalone
app create -name sw_design -hw src/bitstream/ecdsa_project_wrapper.xsa -proc ps7_cortexa9_0 -os standalone -lang C
app build -name sw_design
