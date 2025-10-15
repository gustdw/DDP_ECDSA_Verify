# # check ZYNQ environment variable
ifndef ZYNQ
$(error Please source the source_me file first for the environment variables!)
endif

all: 
	@echo "Valid make targets are:"
	@echo " build     - to create the project"
	@echo " open      - to open the created project"
	@echo " clean     - to delete the project files (your design in \src will be saved)"

open:
	vitis -workspace ./project_sw &

build:
	xsct src/tcl/sdk.tcl
	cp -f project_sw/sw_design/src/lscript.ld src/sw/.
	cp -f project_sw/sw_design/src/Xilinx.spec src/sw/.
	rm -rf project_sw/sw_design/src
	ln -s ../../src/sw/ project_sw/sw_design/src
		
clean:
	rm -rf vitis.* vitis* .Xil/ webtalk* project_sw *.log
