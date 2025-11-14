set_property IOSTANDARD LVCMOS33 [get_ports i_Clk]
set_property LOC W5 [get_ports i_Clk]
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports i_Clk]