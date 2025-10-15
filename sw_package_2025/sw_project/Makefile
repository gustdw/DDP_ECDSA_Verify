# check ZYNQ environment variable
ifndef ZYNQ
$(error Please source the source_me file first for the environment variables!)
endif

all: 
	@echo "Valid make targets are:"
	@echo " build     - to create the project"
	@echo " open      - to open the created project"
	@echo " clean     - to delete the project files (your design in \src will be saved)"
	@echo " hw_import - to import the most updated HDF from Vivado"

open:
	vitis -workspace ./project_sw &

hw_import:
	if [ -a ../hw_project/project_hw/project_hw.sdk/ecc_project_wrapper.hdf ]; then rm -f hwdef.hdf; cp ../hw_project/project_hw/project_hw.sdk/ecc_project_wrapper.hdf hwdef.hdf; fi;
	if [ -a ../hw_project/project_hw/project_hw.sdk/ecc_project_wrapper.hdf ]; then rm -rf ../hw_project/project_hw/project_hw.sdk; fi;
	
build:
	xsct src/tcl/build.tcl
	cp -f project_sw/sw_design/src/lscript.ld src/sw/.
	cp -f project_sw/sw_design/src/Xilinx.spec src/sw/.
	rm -rf project_sw/sw_design/src
	ln -s ../../src/sw/ project_sw/sw_design/src
	rm project_sw/sw_design/Debug/src/helloworld.o
	rm project_sw/sw_design/Debug/src/helloworld.d		
clean:
	rm -rf vitis.* vitis_* .Xil/ webtalk* project_sw
