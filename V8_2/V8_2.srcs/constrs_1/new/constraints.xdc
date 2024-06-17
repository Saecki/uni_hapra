#create_clock -period 8.000 -name ClockIn -waveform {0.000 4.000} [get_ports ClockIn]
set_property PACKAGE_PIN K17 [get_ports Clock]
set_property IOSTANDARD LVCMOS33 [get_ports Clock]

set_property PACKAGE_PIN T16 [get_ports {Switches[3]}]
set_property PACKAGE_PIN W13 [get_ports {Switches[2]}]
set_property PACKAGE_PIN P15 [get_ports {Switches[1]}]
set_property PACKAGE_PIN G15 [get_ports {Switches[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Switches[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Switches[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Switches[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Switches[0]}]

set_property PACKAGE_PIN Y16 [get_ports {Buttons[3]}]
set_property PACKAGE_PIN K19 [get_ports {Buttons[2]}]
set_property PACKAGE_PIN K18 [get_ports {Buttons[0]}]
set_property PACKAGE_PIN P16 [get_ports {Buttons[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Buttons[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Buttons[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Buttons[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Buttons[0]}]

##Pmod Header JC
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { Pins[0] }]; #IO_L10P_T1_34 Sch=JC1_P
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { Pins[1] }]; #IO_L1P_T0_34 Sch=JC2_P
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { Pins[2] }]; #IO_L8P_T1_34 Sch=JC3_P
set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { Pins[3] }]; #IO_L2P_T0_34 Sch=JC4_P
