#*******************************************************************************
# build_audio_platform.tcl  (v2 - bug fixes)
#
# FIXED in this version vs v1:
#   - Removed all use of Tcl variables in cell/pin path strings. Every
#     get_bd_pins / get_bd_intf_pins call now uses literal cell names.
#     (v1 had "[get_bd_pins rst_main/ext_reset_in]" where rst_main was a
#     local Tcl var name, not the cell name - Vivado treated it as literal
#     text "rst_main" and the pin lookup failed.)
#   - Corrected XADC wizard INTERFACE_SELECTION: valid value is {Enable_AXI}
#     (AXI-Stream is enabled via the separate ENABLE_AXI4STREAM parameter).
#   - Corrected proc_sys_reset polarity parameter: it is C_EXT_RESET_HIGH
#     (0 = active-LOW), not C_EXT_RST_HIGHEST_ACTIVE.
#   - Added 'catch { close_project }' at the top so re-running after a
#     failed partial build doesn't collide with leftover project state.
#
# Target: xc7s50csga324-1 (Urbana board, Spartan-7)
# Vivado: 2025.2
#*******************************************************************************

# ---------- User-configurable paths -------------------------------------------
set origin_dir "."
if { [info exists ::origin_dir_loc] } { set origin_dir $::origin_dir_loc }

set AUDIO_HW_PATH [file normalize "$origin_dir/pwm_modulator.vhd"]
if { ![file exists $AUDIO_HW_PATH] } {
    set AUDIO_HW_PATH [file normalize \
        "$origin_dir/../SoC_Final_Project/Audio_Hardware/Hardware/pwm_modulator.vhd"]
}
puts "INFO: pwm_modulator.vhd path = $AUDIO_HW_PATH"
if { ![file exists $AUDIO_HW_PATH] } {
    puts "ERROR: Could not find pwm_modulator.vhd."
    return 1
}

set ADAPTER_PATH [file normalize "$origin_dir/audio_stream_adapter.vhd"]
set XDC_PATH     [file normalize "$origin_dir/../xdc/Urbana_S2026.xdc"]

foreach f [list $ADAPTER_PATH $XDC_PATH] {
    if { ![file exists $f] } {
        puts "ERROR: Required file not found: $f"
        return 1
    }
}

# ---------- Project creation --------------------------------------------------
set _xil_proj_name_ "project_audio"
if { [info exists ::user_project_name] } { set _xil_proj_name_ $::user_project_name }

# Safety: close any leftover project from a previous failed run
catch { close_project }

create_project ${_xil_proj_name_} ./${_xil_proj_name_} -part xc7s50csga324-1 -force
set proj_dir [get_property directory [current_project]]

set_property default_lib        xil_defaultlib                [current_project]
set_property enable_vhdl_2008   1                             [current_project]
set_property simulator_language Mixed                         [current_project]
set_property target_language    Verilog                       [current_project]
set_property xpm_libraries      {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]

# ---------- Source files ------------------------------------------------------
add_files -norecurse -fileset sources_1 [list $AUDIO_HW_PATH $ADAPTER_PATH]
foreach f [list $AUDIO_HW_PATH $ADAPTER_PATH] {
    set fo [get_files -of [get_filesets sources_1] [file tail $f]]
    set_property file_type VHDL $fo
    set_property library xil_defaultlib $fo
}

# ---------- Constraints -------------------------------------------------------
add_files -norecurse -fileset constrs_1 $XDC_PATH
set_property file_type XDC [get_files -of [get_filesets constrs_1] [file tail $XDC_PATH]]

# ==============================================================================
# MIG project file - inlined for self-contained build
# ==============================================================================
proc write_mig_prj { filepath } {
    file mkdir [file dirname $filepath]
    set f [open $filepath w+]
    puts $f {<?xml version="1.0" encoding="UTF-8" standalone="no" ?>}
    puts $f {<Project NoOfControllers="1">}
    puts $f {  <ModuleName>audio_bd_mig_7series_0_0</ModuleName>}
    puts $f {  <dci_inouts_inputs>1</dci_inouts_inputs>}
    puts $f {  <dci_inputs>1</dci_inputs>}
    puts $f {  <Debug_En>OFF</Debug_En>}
    puts $f {  <DataDepth_En>1024</DataDepth_En>}
    puts $f {  <LowPower_En>ON</LowPower_En>}
    puts $f {  <XADC_En>Disabled</XADC_En>}
    puts $f {  <TargetFPGA>xc7s50-csga324/-1</TargetFPGA>}
    puts $f {  <Version>4.2</Version>}
    puts $f {  <SystemClock>No Buffer</SystemClock>}
    puts $f {  <ReferenceClock>No Buffer</ReferenceClock>}
    puts $f {  <SysResetPolarity>ACTIVE HIGH</SysResetPolarity>}
    puts $f {  <BankSelectionFlag>FALSE</BankSelectionFlag>}
    puts $f {  <InternalVref>1</InternalVref>}
    puts $f {  <dci_hr_inouts_inputs>50 Ohms</dci_hr_inouts_inputs>}
    puts $f {  <dci_cascade>0</dci_cascade>}
    puts $f {  <FPGADevice><selected>7s/xc7s25-csga324</selected></FPGADevice>}
    puts $f {  <Controller number="0">}
    puts $f {    <MemoryDevice>DDR3_SDRAM/Components/MT41K64M16XX-125</MemoryDevice>}
    puts $f {    <TimePeriod>3000</TimePeriod>}
    puts $f {    <VccAuxIO>1.8V</VccAuxIO>}
    puts $f {    <PHYRatio>4:1</PHYRatio>}
    puts $f {    <InputClkFreq>333.333</InputClkFreq>}
    puts $f {    <UIExtraClocks>0</UIExtraClocks>}
    puts $f {    <MMCM_VCO>666</MMCM_VCO>}
    puts $f {    <MMCMClkOut0> 1.000</MMCMClkOut0>}
    puts $f {    <MMCMClkOut1>1</MMCMClkOut1>}
    puts $f {    <MMCMClkOut2>1</MMCMClkOut2>}
    puts $f {    <MMCMClkOut3>1</MMCMClkOut3>}
    puts $f {    <MMCMClkOut4>1</MMCMClkOut4>}
    puts $f {    <DataWidth>16</DataWidth>}
    puts $f {    <DeepMemory>1</DeepMemory>}
    puts $f {    <DataMask>1</DataMask>}
    puts $f {    <ECC>Disabled</ECC>}
    puts $f {    <Ordering>Strict</Ordering>}
    puts $f {    <BankMachineCnt>4</BankMachineCnt>}
    puts $f {    <CustomPart>FALSE</CustomPart>}
    puts $f {    <NewPartName/>}
    puts $f {    <RowAddress>13</RowAddress>}
    puts $f {    <ColAddress>10</ColAddress>}
    puts $f {    <BankAddress>3</BankAddress>}
    puts $f {    <MemoryVoltage>1.35V</MemoryVoltage>}
    puts $f {    <C0_MEM_SIZE>134217728</C0_MEM_SIZE>}
    puts $f {    <UserMemoryAddressMap>BANK_ROW_COLUMN</UserMemoryAddressMap>}
    puts $f {    <PinSelection>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V3" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[0]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="U3" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[10]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="P5" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[11]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V6" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[12]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V7" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[13]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="R6" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[14]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="R4" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[1]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="P6" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[2]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="T3" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[3]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="T6" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[4]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="T1" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[5]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V5" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[6]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="U7" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[7]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="R7" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[8]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="U6" SLEW="FAST" VCCAUX_IO="" name="ddr3_addr[9]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V2" SLEW="FAST" VCCAUX_IO="" name="ddr3_ba[0]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V4" SLEW="FAST" VCCAUX_IO="" name="ddr3_ba[1]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="R3" SLEW="FAST" VCCAUX_IO="" name="ddr3_ba[2]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="U1" SLEW="FAST" VCCAUX_IO="" name="ddr3_cas_n"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="DIFF_SSTL135" PADName="T4" SLEW="FAST" VCCAUX_IO="" name="ddr3_ck_n[0]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="DIFF_SSTL135" PADName="R5" SLEW="FAST" VCCAUX_IO="" name="ddr3_ck_p[0]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="T5" SLEW="FAST" VCCAUX_IO="" name="ddr3_cke[0]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="K4" SLEW="FAST" VCCAUX_IO="" name="ddr3_dm[0]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="M3" SLEW="FAST" VCCAUX_IO="" name="ddr3_dm[1]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="K2" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[0]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="P1" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[10]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="N1" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[11]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="R2" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[12]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="N4" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[13]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="P2" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[14]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="M2" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[15]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="M4" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[1]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="K3" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[2]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="L5" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[3]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="L6" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[4]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="M6" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[5]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="L4" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[6]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="K6" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[7]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="N5" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[8]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="SSTL135" PADName="M1" SLEW="FAST" VCCAUX_IO="" name="ddr3_dq[9]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="DIFF_SSTL135" PADName="L1" SLEW="FAST" VCCAUX_IO="" name="ddr3_dqs_n[0]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="DIFF_SSTL135" PADName="N2" SLEW="FAST" VCCAUX_IO="" name="ddr3_dqs_n[1]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="DIFF_SSTL135" PADName="K1" SLEW="FAST" VCCAUX_IO="" name="ddr3_dqs_p[0]"/>}
    puts $f {      <Pin IN_TERM="UNTUNED_SPLIT_50" IOSTANDARD="DIFF_SSTL135" PADName="N3" SLEW="FAST" VCCAUX_IO="" name="ddr3_dqs_p[1]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="P7" SLEW="FAST" VCCAUX_IO="" name="ddr3_odt[0]"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="U2" SLEW="FAST" VCCAUX_IO="" name="ddr3_ras_n"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="M5" SLEW="FAST" VCCAUX_IO="" name="ddr3_reset_n"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="T2" SLEW="FAST" VCCAUX_IO="" name="ddr3_we_n"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="LVDS_25" PADName="B1" SLEW="" VCCAUX_IO="" name="sys_clk_n"/>}
    puts $f {      <Pin IN_TERM="" IOSTANDARD="LVDS_25" PADName="C1" SLEW="" VCCAUX_IO="" name="sys_clk_p"/>}
    puts $f {    </PinSelection>}
    puts $f {    <System_Control>}
    puts $f {      <Pin Bank="Select Bank" PADName="No connect" name="sys_rst"/>}
    puts $f {      <Pin Bank="Select Bank" PADName="No connect" name="init_calib_complete"/>}
    puts $f {      <Pin Bank="15" PADName="C13" name="tg_compare_error"/>}
    puts $f {    </System_Control>}
    puts $f {    <TimingParameters>}
    puts $f {      <Parameters tcke="5" tfaw="40" tras="35" trcd="13.75" trefi="7.8" trfc="110" trp="13.75" trrd="7.5" trtp="7.5" twtr="7.5"/>}
    puts $f {    </TimingParameters>}
    puts $f {    <mrBurstLength name="Burst Length">8 - Fixed</mrBurstLength>}
    puts $f {    <mrBurstType name="Read Burst Type and Length">Sequential</mrBurstType>}
    puts $f {    <mrCasLatency name="CAS Latency">5</mrCasLatency>}
    puts $f {    <mrMode name="Mode">Normal</mrMode>}
    puts $f {    <mrDllReset name="DLL Reset">No</mrDllReset>}
    puts $f {    <mrPdMode name="DLL control for precharge PD">Slow Exit</mrPdMode>}
    puts $f {    <emrDllEnable name="DLL Enable">Enable</emrDllEnable>}
    puts $f {    <emrOutputDriveStrength name="Output Driver Impedance Control">RZQ/7</emrOutputDriveStrength>}
    puts $f {    <emrMirrorSelection name="Address Mirroring">Disable</emrMirrorSelection>}
    puts $f {    <emrCSSelection name="Controller Chip Select Pin">Disable</emrCSSelection>}
    puts $f {    <emrRTT name="RTT (nominal) - On Die Termination (ODT)">RZQ/4</emrRTT>}
    puts $f {    <emrPosted name="Additive Latency (AL)">0</emrPosted>}
    puts $f {    <emrOCD name="Write Leveling Enable">Disabled</emrOCD>}
    puts $f {    <emrDQS name="TDQS enable">Enabled</emrDQS>}
    puts $f {    <emrRDQS name="Qoff">Output Buffer Enabled</emrRDQS>}
    puts $f {    <mr2PartialArraySelfRefresh name="Partial-Array Self Refresh">Full Array</mr2PartialArraySelfRefresh>}
    puts $f {    <mr2CasWriteLatency name="CAS write latency">5</mr2CasWriteLatency>}
    puts $f {    <mr2AutoSelfRefresh name="Auto Self Refresh">Enabled</mr2AutoSelfRefresh>}
    puts $f {    <mr2SelfRefreshTempRange name="High Temparature Self Refresh Rate">Normal</mr2SelfRefreshTempRange>}
    puts $f {    <mr2RTTWR name="RTT_WR - Dynamic On Die Termination (ODT)">Dynamic ODT off</mr2RTTWR>}
    puts $f {    <PortInterface>AXI</PortInterface>}
    puts $f {    <AXIParameters>}
    puts $f {      <C0_C_RD_WR_ARB_ALGORITHM>RD_PRI_REG</C0_C_RD_WR_ARB_ALGORITHM>}
    puts $f {      <C0_S_AXI_ADDR_WIDTH>27</C0_S_AXI_ADDR_WIDTH>}
    puts $f {      <C0_S_AXI_DATA_WIDTH>64</C0_S_AXI_DATA_WIDTH>}
    puts $f {      <C0_S_AXI_ID_WIDTH>4</C0_S_AXI_ID_WIDTH>}
    puts $f {      <C0_S_AXI_SUPPORTS_NARROW_BURST>0</C0_S_AXI_SUPPORTS_NARROW_BURST>}
    puts $f {    </AXIParameters>}
    puts $f {  </Controller>}
    puts $f {</Project>}
    close $f
}

# ==============================================================================
# BLOCK DESIGN
# ==============================================================================
set bd_name audio_bd
create_bd_design $bd_name

# ---------- Top-level ports ---------------------------------------------------
create_bd_port -dir I -type clk -freq_hz 100000000 clk_100MHz
create_bd_port -dir I -type rst reset_n
set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_ports reset_n]
create_bd_port -dir O -from 11 -to 0 LED
create_bd_port -dir O LED_PWM
create_bd_port -dir O SPKL
create_bd_port -dir O SPKR
create_bd_port -dir I vauxp1
create_bd_port -dir I vauxn1
create_bd_port -dir I -from 3 -to 0 switches

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 ddr3

# ==============================================================================
# CLOCKING
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.CLK_OUT1_PORT {clk_100} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.CLK_OUT2_PORT {clk_200} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {333.333} \
    CONFIG.CLK_OUT3_PORT {clk_333} \
    CONFIG.NUM_OUT_CLKS {3} \
    CONFIG.USE_RESET {false} \
] [get_bd_cells clk_wiz_0]

connect_bd_net [get_bd_ports clk_100MHz] [get_bd_pins clk_wiz_0/clk_in1]

# ==============================================================================
# MICROBLAZE
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0
set_property -dict [list \
    CONFIG.C_DEBUG_ENABLED {1} \
    CONFIG.C_AREA_OPTIMIZED {2} \
    CONFIG.C_USE_HW_MUL {2} \
    CONFIG.C_USE_BARREL {1} \
    CONFIG.C_USE_DIV {1} \
    CONFIG.C_USE_FPU {2} \
    CONFIG.C_USE_MSR_INSTR {1} \
    CONFIG.C_USE_PCMP_INSTR {1} \
    CONFIG.C_USE_MMU {3} \
    CONFIG.C_MMU_DTLB_SIZE {4} \
    CONFIG.C_MMU_ITLB_SIZE {2} \
    CONFIG.C_MMU_ZONES {2} \
    CONFIG.C_USE_DCACHE {1} \
    CONFIG.C_DCACHE_BYTE_SIZE {65536} \
    CONFIG.C_DCACHE_BASEADDR {0x0000000080000000} \
    CONFIG.C_DCACHE_HIGHADDR {0x0000000087FFFFFF} \
    CONFIG.C_DCACHE_USE_WRITEBACK {1} \
    CONFIG.C_USE_ICACHE {1} \
    CONFIG.C_CACHE_BYTE_SIZE {65536} \
    CONFIG.C_ICACHE_BASEADDR {0x0000000080000000} \
    CONFIG.C_ICACHE_HIGHADDR {0x0000000087FFFFFF} \
    CONFIG.C_USE_BRANCH_TARGET_CACHE {1} \
    CONFIG.C_BRANCH_TARGET_CACHE_SIZE {6} \
    CONFIG.C_D_LMB {1} \
    CONFIG.C_I_LMB {1} \
    CONFIG.C_D_AXI {1} \
    CONFIG.C_I_AXI {0} \
    CONFIG.C_UNALIGNED_EXCEPTIONS {1} \
    CONFIG.C_ILL_OPCODE_EXCEPTION {1} \
    CONFIG.C_M_AXI_D_BUS_EXCEPTION {1} \
    CONFIG.C_M_AXI_I_BUS_EXCEPTION {1} \
    CONFIG.C_DIV_ZERO_EXCEPTION {1} \
    CONFIG.C_FPU_EXCEPTION {1} \
    CONFIG.C_OPCODE_0x0_ILLEGAL {1} \
    CONFIG.C_PVR {2} \
    CONFIG.G_TEMPLATE_LIST {10} \
    CONFIG.G_USE_EXCEPTIONS {1} \
] [get_bd_cells microblaze_0]

# ---- Local memory ----
create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10
create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10
create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr
create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr
set_property CONFIG.C_ECC {0} [get_bd_cells dlmb_bram_if_cntlr]
set_property CONFIG.C_ECC {0} [get_bd_cells ilmb_bram_if_cntlr]
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram
set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.use_bram_block {BRAM_Controller} \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Use_RSTB_Pin {true} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Port_B_Write_Rate {50} \
] [get_bd_cells lmb_bram]

connect_bd_intf_net [get_bd_intf_pins microblaze_0/DLMB]     [get_bd_intf_pins dlmb_v10/LMB_M]
connect_bd_intf_net [get_bd_intf_pins microblaze_0/ILMB]     [get_bd_intf_pins ilmb_v10/LMB_M]
connect_bd_intf_net [get_bd_intf_pins dlmb_v10/LMB_Sl_0]     [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB]
connect_bd_intf_net [get_bd_intf_pins ilmb_v10/LMB_Sl_0]     [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB]
connect_bd_intf_net [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

# ---- Debug module ----
create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1
connect_bd_intf_net [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]

# ==============================================================================
# RESETS
#   rst_main : peripheral AXI + bus/local-memory reset
#   rst_axi  : DMA + AXI-Stream path reset (separately recyclable)
# Board reset_n is active-LOW, so configure ext_reset_in accordingly.
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_main
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_axi
# Board reset_n is active-LOW. On proc_sys_reset v5.0 the parameter is
# CONFIG.C_EXT_RESET_HIGH: 1 = active-HIGH, 0 = active-LOW.
set_property CONFIG.C_EXT_RESET_HIGH {0} [get_bd_cells rst_main]
set_property CONFIG.C_EXT_RESET_HIGH {0} [get_bd_cells rst_axi]

connect_bd_net [get_bd_ports reset_n]            [get_bd_pins rst_main/ext_reset_in]
connect_bd_net [get_bd_ports reset_n]            [get_bd_pins rst_axi/ext_reset_in]
connect_bd_net [get_bd_pins clk_wiz_0/locked]    [get_bd_pins rst_main/dcm_locked]
connect_bd_net [get_bd_pins clk_wiz_0/locked]    [get_bd_pins rst_axi/dcm_locked]
connect_bd_net [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_main/mb_debug_sys_rst]
connect_bd_net [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_axi/mb_debug_sys_rst]

# LMB + CPU clocks all on clk_100
connect_bd_net [get_bd_pins clk_wiz_0/clk_100] [get_bd_pins microblaze_0/Clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100] [get_bd_pins dlmb_v10/LMB_Clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100] [get_bd_pins ilmb_v10/LMB_Clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100] [get_bd_pins rst_main/slowest_sync_clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100] [get_bd_pins rst_axi/slowest_sync_clk]

connect_bd_net [get_bd_pins rst_main/bus_struct_reset] [get_bd_pins dlmb_v10/SYS_Rst]
connect_bd_net [get_bd_pins rst_main/bus_struct_reset] [get_bd_pins ilmb_v10/SYS_Rst]
connect_bd_net [get_bd_pins rst_main/bus_struct_reset] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst]
connect_bd_net [get_bd_pins rst_main/bus_struct_reset] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst]
connect_bd_net [get_bd_pins rst_main/mb_reset] [get_bd_pins microblaze_0/Reset]

# ==============================================================================
# MIG DDR3 (128 MB)  - lives at 0x80000000
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.2 mig_7series_0

set mig_folder [get_property IP_DIR \
    [get_ips [get_property CONFIG.Component_Name [get_bd_cells mig_7series_0]]]]
write_mig_prj "$mig_folder/mig_b.prj"
set_property -dict [list \
    CONFIG.BOARD_MIG_PARAM {Custom} \
    CONFIG.MIG_DONT_TOUCH_PARAM {Custom} \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
    CONFIG.XML_INPUT_FILE {mig_b.prj} \
] [get_bd_cells mig_7series_0]

# MIG's sys_rst is active-HIGH; our board reset_n is active-LOW, so invert.
create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic:1.0 mig_rst_inv
set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1}] [get_bd_cells mig_rst_inv]
connect_bd_net [get_bd_ports reset_n]        [get_bd_pins mig_rst_inv/Op1]
connect_bd_net [get_bd_pins mig_rst_inv/Res] [get_bd_pins mig_7series_0/sys_rst]

connect_bd_net [get_bd_pins clk_wiz_0/clk_200] [get_bd_pins mig_7series_0/clk_ref_i]
connect_bd_net [get_bd_pins clk_wiz_0/clk_333] [get_bd_pins mig_7series_0/sys_clk_i]
connect_bd_intf_net [get_bd_intf_pins mig_7series_0/DDR3] [get_bd_intf_ports ddr3]

# Reset block for MIG ui_clk domain
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_mig
connect_bd_net [get_bd_pins mig_7series_0/mmcm_locked]     [get_bd_pins rst_mig/dcm_locked]
connect_bd_net [get_bd_pins mig_7series_0/ui_clk]          [get_bd_pins rst_mig/slowest_sync_clk]
connect_bd_net [get_bd_pins mig_7series_0/ui_clk_sync_rst] [get_bd_pins rst_mig/ext_reset_in]
connect_bd_net [get_bd_pins mdm_1/Debug_SYS_Rst]           [get_bd_pins rst_mig/mb_debug_sys_rst]
connect_bd_net [get_bd_pins rst_mig/peripheral_aresetn]    [get_bd_pins mig_7series_0/aresetn]

# ==============================================================================
# DDR SMARTCONNECT
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_ddr
set_property -dict [list CONFIG.NUM_SI {5} CONFIG.NUM_CLKS {2}] [get_bd_cells smartconnect_ddr]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]           [get_bd_pins smartconnect_ddr/aclk]
connect_bd_net [get_bd_pins mig_7series_0/ui_clk]        [get_bd_pins smartconnect_ddr/aclk1]
connect_bd_net [get_bd_pins rst_main/peripheral_aresetn] [get_bd_pins smartconnect_ddr/aresetn]
connect_bd_intf_net [get_bd_intf_pins smartconnect_ddr/M00_AXI] [get_bd_intf_pins mig_7series_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_DC] [get_bd_intf_pins smartconnect_ddr/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_IC] [get_bd_intf_pins smartconnect_ddr/S01_AXI]

# ==============================================================================
# PERIPHERAL SMARTCONNECT
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_peri
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {8}] [get_bd_cells smartconnect_peri]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]           [get_bd_pins smartconnect_peri/aclk]
connect_bd_net [get_bd_pins rst_main/peripheral_aresetn] [get_bd_pins smartconnect_peri/aresetn]
connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins smartconnect_peri/S00_AXI]

# ---- UART Lite ---------------------------------------------------------------
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0
set_property CONFIG.C_BAUDRATE {115200} [get_bd_cells axi_uartlite_0]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]           [get_bd_pins axi_uartlite_0/s_axi_aclk]
connect_bd_net [get_bd_pins rst_main/peripheral_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn]
connect_bd_intf_net [get_bd_intf_pins smartconnect_peri/M00_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_uartlite_0/UART] [get_bd_intf_ports uart]

# ---- Timer -------------------------------------------------------------------
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 axi_timer_0
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]           [get_bd_pins axi_timer_0/s_axi_aclk]
connect_bd_net [get_bd_pins rst_main/peripheral_aresetn] [get_bd_pins axi_timer_0/s_axi_aresetn]
connect_bd_intf_net [get_bd_intf_pins smartconnect_peri/M01_AXI] [get_bd_intf_pins axi_timer_0/S_AXI]

# ---- INTC --------------------------------------------------------------------
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc_0
set_property CONFIG.C_HAS_FAST {1} [get_bd_cells axi_intc_0]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]           [get_bd_pins axi_intc_0/s_axi_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]           [get_bd_pins axi_intc_0/processor_clk]
connect_bd_net [get_bd_pins rst_main/peripheral_aresetn] [get_bd_pins axi_intc_0/s_axi_aresetn]
connect_bd_net [get_bd_pins rst_main/mb_reset]           [get_bd_pins axi_intc_0/processor_rst]
connect_bd_intf_net [get_bd_intf_pins smartconnect_peri/M02_AXI] [get_bd_intf_pins axi_intc_0/s_axi]
connect_bd_intf_net [get_bd_intf_pins axi_intc_0/interrupt] [get_bd_intf_pins microblaze_0/INTERRUPT]

create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat:1.0 intr_concat
set_property CONFIG.NUM_PORTS {4} [get_bd_cells intr_concat]
connect_bd_net [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins intr_concat/In0]
connect_bd_net [get_bd_pins axi_timer_0/interrupt]    [get_bd_pins intr_concat/In1]
connect_bd_net [get_bd_pins intr_concat/dout]         [get_bd_pins axi_intc_0/intr]

# ---- AXI GPIO (LEDs) ---------------------------------------------------------
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_led
set_property -dict [list CONFIG.C_GPIO_WIDTH {12} CONFIG.C_ALL_OUTPUTS {1}] [get_bd_cells axi_gpio_led]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]           [get_bd_pins axi_gpio_led/s_axi_aclk]
connect_bd_net [get_bd_pins rst_main/peripheral_aresetn] [get_bd_pins axi_gpio_led/s_axi_aresetn]
connect_bd_intf_net [get_bd_intf_pins smartconnect_peri/M03_AXI] [get_bd_intf_pins axi_gpio_led/S_AXI]
connect_bd_net [get_bd_pins axi_gpio_led/gpio_io_o] [get_bd_ports LED]

# ---- AXI GPIO (switches in, control out) -------------------------------------
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_ctrl
set_property -dict [list \
    CONFIG.C_IS_DUAL {1} \
    CONFIG.C_GPIO_WIDTH {4} \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_GPIO2_WIDTH {8} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
] [get_bd_cells axi_gpio_ctrl]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]           [get_bd_pins axi_gpio_ctrl/s_axi_aclk]
connect_bd_net [get_bd_pins rst_main/peripheral_aresetn] [get_bd_pins axi_gpio_ctrl/s_axi_aresetn]
connect_bd_intf_net [get_bd_intf_pins smartconnect_peri/M06_AXI] [get_bd_intf_pins axi_gpio_ctrl/S_AXI]
connect_bd_net [get_bd_ports switches] [get_bd_pins axi_gpio_ctrl/gpio_io_i]

# Loopback enable bit extraction
create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice:1.0 slice_loopback
set_property -dict [list CONFIG.DIN_WIDTH {8} CONFIG.DIN_FROM {0} CONFIG.DIN_TO {0}] [get_bd_cells slice_loopback]
connect_bd_net [get_bd_pins axi_gpio_ctrl/gpio2_io_o] [get_bd_pins slice_loopback/Din]

# ==============================================================================
# XADC WIZARD
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:xadc_wiz:3.3 xadc_wiz_0
# Note: INTERFACE_SELECTION = Enable_AXI selects the AXI-Lite interface
# (for runtime config at 0x44A00000). AXI4-Stream is a separate enable
# controlled by ENABLE_AXI4STREAM, which adds the M_AXIS data output.
set_property -dict [list \
    CONFIG.INTERFACE_SELECTION {Enable_AXI} \
    CONFIG.ENABLE_AXI4STREAM {true} \
    CONFIG.DCLK_FREQUENCY {100} \
    CONFIG.ADC_CONVERSION_RATE {1000} \
    CONFIG.XADC_STARUP_SELECTION {single_channel} \
    CONFIG.SINGLE_CHANNEL_SELECTION {VAUXP1_VAUXN1} \
    CONFIG.CHANNEL_ENABLE_VAUXP1_VAUXN1 {true} \
    CONFIG.CHANNEL_ENABLE_TEMPERATURE {false} \
    CONFIG.SEQUENCER_MODE {Off} \
    CONFIG.OT_ALARM {false} \
    CONFIG.USER_TEMP_ALARM {false} \
    CONFIG.VCCINT_ALARM {false} \
    CONFIG.VCCAUX_ALARM {false} \
    CONFIG.AVERAGE_ENABLE_VAUXP1_VAUXN1 {true} \
    CONFIG.BIPOLAR_VAUXP1_VAUXN1 {true} \
] [get_bd_cells xadc_wiz_0]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]           [get_bd_pins xadc_wiz_0/s_axi_aclk]
connect_bd_net [get_bd_pins rst_main/peripheral_aresetn] [get_bd_pins xadc_wiz_0/s_axi_aresetn]
connect_bd_intf_net [get_bd_intf_pins smartconnect_peri/M05_AXI] [get_bd_intf_pins xadc_wiz_0/s_axi_lite]
connect_bd_net [get_bd_ports vauxp1] [get_bd_pins xadc_wiz_0/vauxp1]
connect_bd_net [get_bd_ports vauxn1] [get_bd_pins xadc_wiz_0/vauxn1]

# ==============================================================================
# AXI DMA (Scatter-Gather)
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
set_property -dict [list \
    CONFIG.c_include_sg {1} \
    CONFIG.c_sg_length_width {23} \
    CONFIG.c_sg_include_stscntrl_strm {0} \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_m_axi_mm2s_data_width {32} \
    CONFIG.c_m_axis_mm2s_tdata_width {32} \
    CONFIG.c_m_axi_s2mm_data_width {32} \
    CONFIG.c_s_axis_s2mm_tdata_width {32} \
    CONFIG.c_mm2s_burst_size {16} \
    CONFIG.c_s2mm_burst_size {16} \
    CONFIG.c_include_mm2s_dre {0} \
    CONFIG.c_include_s2mm_dre {0} \
] [get_bd_cells axi_dma_0]

connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axi_dma_0/s_axi_lite_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axi_dma_0/m_axi_sg_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axi_dma_0/m_axi_mm2s_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axi_dma_0/m_axi_s2mm_aclk]
connect_bd_net [get_bd_pins rst_axi/peripheral_aresetn] [get_bd_pins axi_dma_0/axi_resetn]

connect_bd_intf_net [get_bd_intf_pins smartconnect_peri/M04_AXI] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_SG]   [get_bd_intf_pins smartconnect_ddr/S02_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins smartconnect_ddr/S03_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins smartconnect_ddr/S04_AXI]

connect_bd_net [get_bd_pins axi_dma_0/mm2s_introut] [get_bd_pins intr_concat/In2]
connect_bd_net [get_bd_pins axi_dma_0/s2mm_introut] [get_bd_pins intr_concat/In3]

# ==============================================================================
# CAPTURE STREAM
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_conv_xadc
set_property -dict [list \
    CONFIG.S_TDATA_NUM_BYTES {4} \
    CONFIG.M_TDATA_NUM_BYTES {4} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.S_HAS_TKEEP {0} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_HAS_TSTRB {0} \
    CONFIG.S_HAS_TLAST {0} \
    CONFIG.S_HAS_TUSER {0} \
    CONFIG.TDATA_REMAP {tdata[31:0]} \
    CONFIG.TLAST_REMAP {1'b0} \
    CONFIG.TUSER_BITS_PER_BYTE {0} \
] [get_bd_cells axis_subset_conv_xadc]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axis_subset_conv_xadc/aclk]
connect_bd_net [get_bd_pins rst_axi/peripheral_aresetn] [get_bd_pins axis_subset_conv_xadc/aresetn]
connect_bd_intf_net [get_bd_intf_pins xadc_wiz_0/M_AXIS] [get_bd_intf_pins axis_subset_conv_xadc/S_AXIS]

create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_cap
set_property -dict [list \
    CONFIG.FIFO_DEPTH {1024} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.TDATA_NUM_BYTES {4} \
    CONFIG.IS_ACLK_ASYNC {0} \
] [get_bd_cells axis_data_fifo_cap]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axis_data_fifo_cap/s_axis_aclk]
connect_bd_net [get_bd_pins rst_axi/peripheral_aresetn] [get_bd_pins axis_data_fifo_cap/s_axis_aresetn]
connect_bd_intf_net [get_bd_intf_pins axis_subset_conv_xadc/M_AXIS] [get_bd_intf_pins axis_data_fifo_cap/S_AXIS]

# ==============================================================================
# PLAYBACK STREAM
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_play
set_property -dict [list \
    CONFIG.FIFO_DEPTH {1024} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.TDATA_NUM_BYTES {4} \
    CONFIG.IS_ACLK_ASYNC {0} \
] [get_bd_cells axis_data_fifo_play]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axis_data_fifo_play/s_axis_aclk]
connect_bd_net [get_bd_pins rst_axi/peripheral_aresetn] [get_bd_pins axis_data_fifo_play/s_axis_aresetn]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins axis_data_fifo_play/S_AXIS]

create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_bcast_play
set_property -dict [list \
    CONFIG.NUM_MI {2} \
    CONFIG.S_TDATA_NUM_BYTES {4} \
    CONFIG.M_TDATA_NUM_BYTES {4} \
    CONFIG.M00_TDATA_REMAP {tdata[31:0]} \
    CONFIG.M01_TDATA_REMAP {tdata[31:0]} \
    CONFIG.S_HAS_TLAST {1} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.S_HAS_TKEEP {0} \
    CONFIG.M_HAS_TKEEP {0} \
    CONFIG.S_HAS_TSTRB {0} \
    CONFIG.M_HAS_TSTRB {0} \
] [get_bd_cells axis_bcast_play]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axis_bcast_play/aclk]
connect_bd_net [get_bd_pins rst_axi/peripheral_aresetn] [get_bd_pins axis_bcast_play/aresetn]
connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_play/M_AXIS] [get_bd_intf_pins axis_bcast_play/S_AXIS]

# ==============================================================================
# AXI-Stream SWITCH (ADC or loopback into DMA.S2MM)
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 axis_switch_s2mm
set_property -dict [list \
    CONFIG.NUM_SI {2} \
    CONFIG.NUM_MI {1} \
    CONFIG.ROUTING_MODE {1} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.TDATA_NUM_BYTES {4} \
    CONFIG.DECODER_REG {1} \
    CONFIG.ARB_ON_TLAST {1} \
] [get_bd_cells axis_switch_s2mm]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axis_switch_s2mm/aclk]
connect_bd_net [get_bd_pins rst_axi/peripheral_aresetn] [get_bd_pins axis_switch_s2mm/aresetn]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axis_switch_s2mm/s_axi_ctrl_aclk]
connect_bd_net [get_bd_pins rst_axi/peripheral_aresetn] [get_bd_pins axis_switch_s2mm/s_axi_ctrl_aresetn]
connect_bd_intf_net [get_bd_intf_pins smartconnect_peri/M07_AXI] [get_bd_intf_pins axis_switch_s2mm/S_AXI_CTRL]

connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_cap/M_AXIS] [get_bd_intf_pins axis_switch_s2mm/S00_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_bcast_play/M01_AXIS]  [get_bd_intf_pins axis_switch_s2mm/S01_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_switch_s2mm/M00_AXIS] [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]

# ==============================================================================
# ADAPTER + PWM
# ==============================================================================
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_conv_play
set_property -dict [list \
    CONFIG.S_TDATA_NUM_BYTES {4} \
    CONFIG.M_TDATA_NUM_BYTES {2} \
    CONFIG.TDATA_REMAP {tdata[15:0]} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.S_HAS_TLAST {1} \
    CONFIG.S_HAS_TKEEP {0} \
    CONFIG.M_HAS_TKEEP {0} \
    CONFIG.S_HAS_TSTRB {0} \
    CONFIG.M_HAS_TSTRB {0} \
    CONFIG.S_HAS_TUSER {0} \
] [get_bd_cells axis_subset_conv_play]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins axis_subset_conv_play/aclk]
connect_bd_net [get_bd_pins rst_axi/peripheral_aresetn] [get_bd_pins axis_subset_conv_play/aresetn]
connect_bd_intf_net [get_bd_intf_pins axis_bcast_play/M00_AXIS] [get_bd_intf_pins axis_subset_conv_play/S_AXIS]

create_bd_cell -type module -reference audio_stream_adapter audio_stream_adapter_0
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins audio_stream_adapter_0/clk]
connect_bd_net [get_bd_pins rst_axi/peripheral_aresetn] [get_bd_pins audio_stream_adapter_0/rstn]
connect_bd_intf_net [get_bd_intf_pins axis_subset_conv_play/M_AXIS] [get_bd_intf_pins audio_stream_adapter_0/S_AXIS]

create_bd_cell -type module -reference pwm_modulator pwm_modulator_0
set_property CONFIG.pwm_bits {12} [get_bd_cells pwm_modulator_0]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100]          [get_bd_pins pwm_modulator_0/clk]
connect_bd_net [get_bd_pins rst_axi/peripheral_aresetn] [get_bd_pins pwm_modulator_0/rstn]
connect_bd_net [get_bd_pins audio_stream_adapter_0/duty_cycle] [get_bd_pins pwm_modulator_0/duty_cycle]
connect_bd_net [get_bd_pins pwm_modulator_0/pwm_out] [get_bd_ports SPKL]
connect_bd_net [get_bd_pins pwm_modulator_0/pwm_out] [get_bd_ports SPKR]
connect_bd_net [get_bd_pins pwm_modulator_0/pwm_out] [get_bd_ports LED_PWM]

# ==============================================================================
# ADDRESS MAP
# ==============================================================================
assign_bd_address -offset 0x40600000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Data] \
    [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force
assign_bd_address -offset 0x41C00000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Data] \
    [get_bd_addr_segs axi_timer_0/S_AXI/Reg] -force
assign_bd_address -offset 0x41200000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Data] \
    [get_bd_addr_segs axi_intc_0/S_AXI/Reg] -force
assign_bd_address -offset 0x40000000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Data] \
    [get_bd_addr_segs axi_gpio_led/S_AXI/Reg] -force
assign_bd_address -offset 0x40010000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Data] \
    [get_bd_addr_segs axi_gpio_ctrl/S_AXI/Reg] -force
assign_bd_address -offset 0x41E00000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Data] \
    [get_bd_addr_segs axi_dma_0/S_AXI_LITE/Reg] -force
assign_bd_address -offset 0x44A00000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Data] \
    [get_bd_addr_segs xadc_wiz_0/s_axi_lite/Reg] -force
assign_bd_address -offset 0x44A10000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Data] \
    [get_bd_addr_segs axis_switch_s2mm/S_AXI_CTRL/Reg] -force
assign_bd_address -offset 0x00000000 -range 0x00004000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Data] \
    [get_bd_addr_segs dlmb_bram_if_cntlr/SLMB/Mem] -force
assign_bd_address -offset 0x00000000 -range 0x00004000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] \
    [get_bd_addr_segs ilmb_bram_if_cntlr/SLMB/Mem] -force
assign_bd_address -offset 0x80000000 -range 0x08000000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Data] \
    [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
assign_bd_address -offset 0x80000000 -range 0x08000000 \
    -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] \
    [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
assign_bd_address -offset 0x80000000 -range 0x08000000 \
    -target_address_space [get_bd_addr_spaces axi_dma_0/Data_SG] \
    [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
assign_bd_address -offset 0x80000000 -range 0x08000000 \
    -target_address_space [get_bd_addr_spaces axi_dma_0/Data_MM2S] \
    [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
assign_bd_address -offset 0x80000000 -range 0x08000000 \
    -target_address_space [get_bd_addr_spaces axi_dma_0/Data_S2MM] \
    [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force

# ==============================================================================
# VALIDATE, WRAP, BUILD, EXPORT
# ==============================================================================
validate_bd_design
save_bd_design
regenerate_bd_layout

make_wrapper -files [get_files ${bd_name}.bd] -top -import -force
set_property top ${bd_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "INFO: Starting synthesis..."
launch_runs synth_1 -jobs 8
wait_on_run synth_1

puts "INFO: Starting implementation + bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

puts "INFO: Exporting XSA..."
set xsa_path "${proj_dir}/${_xil_proj_name_}.xsa"
write_hw_platform -fixed -include_bit -force -file $xsa_path

puts ""
puts "=================================================================="
puts "BUILD COMPLETE"
puts "XSA: $xsa_path"
puts "=================================================================="
