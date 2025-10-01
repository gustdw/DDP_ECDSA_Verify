# check ZYNQ environment variable
ifndef ZYNQ
$(error Please source the source_me file first for the environment variables!)
endif

all:
	@echo "Valid make targets are:"
	@echo " warmup    - to create the warm-up project"
	@echo " adder     - to create the adder project"
	@echo " mult      - to create the multiplier project"
	@echo " ecdsa     - to create the ECDSA project"
	@echo " open      - to open the created project"
	@echo " clean     - to delete the project files (your design in \src will be saved)"
	@echo " hw_export - to export the bitstream file to the SW project"

warmup:
	vivado -mode batch -source tcl/build_warmup.tcl

adder: 
	vivado -mode batch -source tcl/build_project.tcl -tclargs adder

mult: 
	vivado -mode batch -source tcl/build_project.tcl -tclargs mult

ecdsa:
	vivado -mode batch -source tcl/build_project.tcl -tclargs ecdsa

build: ecdsa

open:
	vivado project_hw/project_hw.xpr -tempDir /tmp &

hw_export:
	vivado -mode batch -source tcl/hw_export.tcl

clean:
	rm -rf vivado.* vivado_* .Xil/ webtalk* NA
	rm -rf project_hw project_ipcores
