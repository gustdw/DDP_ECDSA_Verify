
################################################################
# This is a generated script based on design: tb_ecdsa_project
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2023.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source tb_ecdsa_project_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# tb_mem, ecdsa, interfacer

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z020clg400-1
   set_property BOARD_PART tul.com.tw:pynq-z2:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name tb_ecdsa_project

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_bram_ctrl:4.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
tb_mem\
ecdsa\
interfacer\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set mem [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 mem ]
  set_property -dict [ list \
   CONFIG.MASTER_TYPE {BRAM_CTRL} \
   CONFIG.MEM_SIZE {16384} \
   CONFIG.MEM_WIDTH {1024} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   ] $mem

  set s_axi_csrs [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_csrs ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {12} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {4} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {4} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $s_axi_csrs


  # Create ports
  set clk [ create_bd_port -dir I -type clk -freq_hz 100000000 clk ]
  set_property -dict [ list \
   CONFIG.CLK_DOMAIN {ecdsa_project_processing_system7_0_0_FCLK_CLK0} \
 ] $clk
  set leds [ create_bd_port -dir O -from 3 -to 0 leds ]
  set resetn [ create_bd_port -dir I -type rst resetn ]

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {1024} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_0


  # Create instance: tb_mem_0, and set properties
  set block_name tb_mem
  set block_cell_name tb_mem_0
  if { [catch {set tb_mem_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $tb_mem_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ecdsa_0, and set properties
  set block_name ecdsa
  set block_cell_name ecdsa_0
  if { [catch {set ecdsa_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ecdsa_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: interfacer_0, and set properties
  set block_name interfacer
  set block_cell_name interfacer_0
  if { [catch {set interfacer_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $interfacer_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins tb_mem_0/brama]
  connect_bd_intf_net -intf_net interfacer_0_m_axi_dma [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins interfacer_0/m_axi_dma]
  connect_bd_intf_net -intf_net mem_1 [get_bd_intf_pins tb_mem_0/bramb] [get_bd_intf_ports mem]
  connect_bd_intf_net -intf_net s_axi_csrs_1 [get_bd_intf_pins interfacer_0/s_axi_csrs] [get_bd_intf_ports s_axi_csrs]

  # Create port connections
  connect_bd_net -net Net [get_bd_ports clk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins ecdsa_0/clk] [get_bd_pins interfacer_0/aclk]
  connect_bd_net -net interfacer_0_csr0_c2f [get_bd_pins interfacer_0/csr0_c2f] [get_bd_pins ecdsa_0/rin0]
  connect_bd_net -net interfacer_0_csr1_c2f [get_bd_pins interfacer_0/csr1_c2f] [get_bd_pins ecdsa_0/rin1]
  connect_bd_net -net interfacer_0_csr2_c2f [get_bd_pins interfacer_0/csr2_c2f] [get_bd_pins ecdsa_0/rin2]
  connect_bd_net -net interfacer_0_csr3_c2f [get_bd_pins interfacer_0/csr3_c2f] [get_bd_pins ecdsa_0/rin3]
  connect_bd_net -net interfacer_0_csr4_c2f [get_bd_pins interfacer_0/csr4_c2f] [get_bd_pins ecdsa_0/rin4]
  connect_bd_net -net interfacer_0_csr5_c2f [get_bd_pins interfacer_0/csr5_c2f] [get_bd_pins ecdsa_0/rin5]
  connect_bd_net -net interfacer_0_csr6_c2f [get_bd_pins interfacer_0/csr6_c2f] [get_bd_pins ecdsa_0/rin6]
  connect_bd_net -net interfacer_0_csr7_c2f [get_bd_pins interfacer_0/csr7_c2f] [get_bd_pins ecdsa_0/rin7]
  connect_bd_net -net interfacer_0_dma_c2f_data [get_bd_pins interfacer_0/dma_c2f_data] [get_bd_pins ecdsa_0/dma_rx_data]
  connect_bd_net -net interfacer_0_dma_done [get_bd_pins interfacer_0/dma_done] [get_bd_pins ecdsa_0/dma_done]
  connect_bd_net -net interfacer_0_dma_error [get_bd_pins interfacer_0/dma_error] [get_bd_pins ecdsa_0/dma_error]
  connect_bd_net -net interfacer_0_dma_idle [get_bd_pins interfacer_0/dma_idle] [get_bd_pins ecdsa_0/dma_idle]
  connect_bd_net -net ecdsa_0_dma_rx_address [get_bd_pins ecdsa_0/dma_rx_address] [get_bd_pins interfacer_0/dma_c2f_addr]
  connect_bd_net -net ecdsa_0_dma_rx_start [get_bd_pins ecdsa_0/dma_rx_start] [get_bd_pins interfacer_0/dma_c2f_start]
  connect_bd_net -net ecdsa_0_dma_tx_address [get_bd_pins ecdsa_0/dma_tx_address] [get_bd_pins interfacer_0/dma_f2c_addr]
  connect_bd_net -net ecdsa_0_dma_tx_data [get_bd_pins ecdsa_0/dma_tx_data] [get_bd_pins interfacer_0/dma_f2c_data]
  connect_bd_net -net ecdsa_0_dma_tx_start [get_bd_pins ecdsa_0/dma_tx_start] [get_bd_pins interfacer_0/dma_f2c_start]
  connect_bd_net -net ecdsa_0_leds [get_bd_pins ecdsa_0/leds] [get_bd_ports leds]
  connect_bd_net -net ecdsa_0_rout0 [get_bd_pins ecdsa_0/rout0] [get_bd_pins interfacer_0/csr0_f2c]
  connect_bd_net -net ecdsa_0_rout1 [get_bd_pins ecdsa_0/rout1] [get_bd_pins interfacer_0/csr1_f2c]
  connect_bd_net -net ecdsa_0_rout2 [get_bd_pins ecdsa_0/rout2] [get_bd_pins interfacer_0/csr2_f2c]
  connect_bd_net -net ecdsa_0_rout3 [get_bd_pins ecdsa_0/rout3] [get_bd_pins interfacer_0/csr3_f2c]
  connect_bd_net -net ecdsa_0_rout4 [get_bd_pins ecdsa_0/rout4] [get_bd_pins interfacer_0/csr4_f2c]
  connect_bd_net -net ecdsa_0_rout5 [get_bd_pins ecdsa_0/rout5] [get_bd_pins interfacer_0/csr5_f2c]
  connect_bd_net -net ecdsa_0_rout6 [get_bd_pins ecdsa_0/rout6] [get_bd_pins interfacer_0/csr6_f2c]
  connect_bd_net -net ecdsa_0_rout7 [get_bd_pins ecdsa_0/rout7] [get_bd_pins interfacer_0/csr7_f2c]
  connect_bd_net -net rst_ps7_0_100M_peripheral_aresetn [get_bd_ports resetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins ecdsa_0/resetn] [get_bd_pins interfacer_0/aresetn]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00004000 -target_address_space [get_bd_addr_spaces interfacer_0/m_axi_dma] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces s_axi_csrs] [get_bd_addr_segs interfacer_0/s_axi_csrs/reg0] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


